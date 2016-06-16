// SBTUITestTunnelServer.m
//
// Copyright (C) 2016 Subito.it S.r.l (www.subito.it)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if DEBUG

#import "SBTUITestTunnelServer.h"
#import "SBTUITestTunnel.h"
#import "NSURLRequest+SBTUITestTunnelMatch.h"
#import "SBTProxyURLProtocol.h"
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerURLEncodedFormRequest.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>
#import <NSHash/NSData+NSHash.h>
#import <FXKeyChain/FXKeyChain.h>
#import <CoreLocation/CoreLocation.h>

#if !defined(NS_BLOCK_ASSERTIONS)

#define BlockAssert(condition, desc, ...) \
do {\
if (!(condition)) { \
[[NSAssertionHandler currentHandler] handleFailureInFunction:NSStringFromSelector(_cmd) \
file:[NSString stringWithUTF8String:__FILE__] \
lineNumber:__LINE__ \
description:(desc), ##__VA_ARGS__]; \
}\
} while(0);

#else // NS_BLOCK_ASSERTIONS defined

#define BlockAssert(condition, desc, ...)

#endif

@implementation GCDWebServerRequest (Extension)

- (NSDictionary *)parameters
{
    if ([self isKindOfClass:[GCDWebServerURLEncodedFormRequest class]]) {
        return ((GCDWebServerURLEncodedFormRequest *)self).arguments;
    } else {
        return self.query;
    }
}

@end

@interface SBTUITestTunnelServer()

@property (nonatomic, strong) GCDWebServer *server;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSObject<OHHTTPStubsDescriptor> *> *activeStubs;
@property (nonatomic, strong) NSCountedSet<NSString *> *stubsToRemoveAfterCount;
@property (nonatomic, strong) NSMutableArray<SBTMonitoredNetworkRequest *> *monitoredRequests;
@property (nonatomic, strong) dispatch_queue_t commandDispatchQueue;
@property (nonatomic, assign) BOOL startupCommandsCompleted;

@end

@implementation SBTUITestTunnelServer

+ (SBTUITestTunnelServer *)sharedInstance
{
    static SBTUITestTunnelServer *sharedInstance;
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[SBTUITestTunnelServer alloc] init];
            sharedInstance.server = [[GCDWebServer alloc] init];
            sharedInstance.activeStubs = [NSMutableDictionary dictionary];
            sharedInstance.stubsToRemoveAfterCount = [NSCountedSet set];
            sharedInstance.monitoredRequests = [NSMutableArray array];
            sharedInstance.commandDispatchQueue = dispatch_queue_create("com.sbtuitesttunnel.queue.command", DISPATCH_QUEUE_SERIAL);
            sharedInstance.startupCommandsCompleted = YES;
        }
    }
    return sharedInstance;
}

+ (void)takeOff
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [self.sharedInstance takeOffOnce];
    });
}

- (void)takeOffOnce
{
    NSDictionary<NSString *, NSString *> *environment = [NSProcessInfo processInfo].environment;
    NSString *bonjourName = environment[SBTUITunneledApplicationLaunchEnvironmentBonjourNameKey];
    NSString *portString = environment[SBTUITunneledApplicationLaunchEnvironmentRemotePortKey];
    NSInteger serverPort = [portString integerValue];
    
    if (!bonjourName || !portString) {
        // Required methods missing, presumely app wasn't launched from ui test
        NSLog(@"[UITestTunnelServer] required environment parameters missing, safely landing");
        return;
    }
    
    [NSURLProtocol registerClass:[SBTProxyURLProtocol class]];
    
    Class requestClass = ([SBTUITunnelHTTPMethod isEqualToString:@"POST"]) ? [GCDWebServerURLEncodedFormRequest class] : [GCDWebServerRequest class];
    
    __weak typeof(self) weakSelf = self;
    [self.server addDefaultHandlerForMethod:SBTUITunnelHTTPMethod requestClass:requestClass processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        __block GCDWebServerDataResponse *ret;
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        dispatch_async(weakSelf.commandDispatchQueue, ^{
            // NSLog(@"[UITestTunnelServer] received command %@", request.path);
            
            NSString *command = [request.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
            
            NSString *commandString = [command stringByAppendingString:@":"];
            SEL commandSelector = NSSelectorFromString(commandString);
            if (![weakSelf respondsToSelector:commandSelector]) {
                BlockAssert(NO, @"[UITestTunnelServer] Unhandled/unknown command! %@", command);
            }
            IMP imp = [weakSelf methodForSelector:commandSelector];
            
            NSString * (*func)(id, SEL, GCDWebServerRequest *) = (void *)imp;
            NSString *response = func(weakSelf, commandSelector, request);
            
            ret = [GCDWebServerDataResponse responseWithJSONObject:@{ SBTUITunnelResponseResultKey: response ?: @"" }];
            
            dispatch_semaphore_signal(sem);
        });
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        return ret;
    }];
    
    [self processLaunchOptionsIfNeeded];
    
    [GCDWebServer setLogLevel:3];
    [self.server startWithPort:serverPort bonjourName:bonjourName];
    
    [self processStartupCommandsIfNeeded];
    
    NSLog(@"[UITestTunnelServer] Up and running!");
}

/* Rememeber to always return something at the end of the command otherwise [self performSelector] will crash with an EXC_I386_GPFLT */

#pragma mark - Stubs Commands

- (NSString *)commandStubPathThathMatchesRegex:(GCDWebServerRequest *)tunnelRequest
{
    NSString *stubId = [self identifierForStubRequest:tunnelRequest];
    if (self.activeStubs[stubId]) {
        // existing stub found, replacing with new one
        NSLog(@"[UITestTunnelServer] Warning existing stub found, replacing it");
    
        [OHHTTPStubs removeStub:self.activeStubs[stubId]];
    }

    id<OHHTTPStubsDescriptor> stub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        if ([self validStubRequest:tunnelRequest]) {
            NSData *responseData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelStubQueryRuleKey] options:0];
            NSString *regexPattern = [NSKeyedUnarchiver unarchiveObjectWithData:responseData];
            
            return [request matchesRegexPattern:regexPattern];
        }
        return NO;
        
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [self responseForStubRequest:tunnelRequest withStubId:stubId];
    }];
    
    self.activeStubs[stubId] = stub;
    return stubId;
}

- (NSString *)commandStubPathThathContainsQueryParams:(GCDWebServerRequest *)tunnelRequest
{
    NSString *stubId = [self identifierForStubRequest:tunnelRequest];
    if (self.activeStubs[stubId]) {
        // existing stub found, replacing with new one
        NSLog(@"[UITestTunnelServer] Warning existing stub found, replacing it");
        
        [OHHTTPStubs removeStub:self.activeStubs[stubId]];
    }
    
    id<OHHTTPStubsDescriptor> stub = [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        if ([self validStubRequest:tunnelRequest]) {
            NSData *responseData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelStubQueryRuleKey] options:0];
            NSArray<NSString *> *queries = [NSKeyedUnarchiver unarchiveObjectWithData:responseData];
            
            return [request matchesQueryParams:queries];
        }
        return NO;
        
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [self responseForStubRequest:tunnelRequest withStubId:stubId];
    }];
    
    self.activeStubs[stubId] = stub;
    return stubId;
}

#pragma mark - Stub and Remove Commands

- (NSString *)commandStubAndRemovePathThathMatchesRegex:(GCDWebServerRequest *)tunnelRequest
{
    if ([self validStubRequest:tunnelRequest]) {
        NSInteger stubRequestsRemoveAfterCount = [tunnelRequest.parameters[SBTUITunnelStubQueryIterations] integerValue];
        
        for (NSInteger i = 0; i < stubRequestsRemoveAfterCount; i++) {
            [self.stubsToRemoveAfterCount addObject:[self identifierForStubRequest:tunnelRequest]];
        }
        
        return [self commandStubPathThathMatchesRegex:tunnelRequest].length > 0 ? @"YES" : @"NO";
    }
    
    return @"NO";
}

- (NSString *)commandStubAndRemovePathThathContainsQueryParams:(GCDWebServerRequest *)tunnelRequest
{
    if ([self validStubRequest:tunnelRequest]) {
        NSInteger stubRequestsRemoveAfterCount = [tunnelRequest.parameters[SBTUITunnelStubQueryIterations] integerValue];
        
        for (NSInteger i = 0; i < stubRequestsRemoveAfterCount; i++) {
            [self.stubsToRemoveAfterCount addObject:[self identifierForStubRequest:tunnelRequest]];
        }
        
        return [self commandStubPathThathContainsQueryParams:tunnelRequest].length > 0 ? @"YES" : @"NO";
    }
    
    return @"NO";
}

- (NSString *)commandStubRequestsRemove:(GCDWebServerRequest *)tunnelRequest
{
    NSData *responseData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelStubQueryRuleKey] options:0];
    NSString *stubId = [NSKeyedUnarchiver unarchiveObjectWithData:responseData];
    
    if (!self.activeStubs[stubId] || [self.stubsToRemoveAfterCount countForObject:stubId] > 0) {
        return @"NO";
    }
    
    if ([OHHTTPStubs removeStub:self.activeStubs[stubId]]) {
        [self.activeStubs removeObjectForKey:stubId];
    }
    
    return @"YES";
}

- (NSString *)commandStubRequestsRemoveAll:(GCDWebServerRequest *)tunnelRequest
{
    NSMutableArray<NSString *> *keysToRemove = [NSMutableArray array];
    [self.activeStubs enumerateKeysAndObjectsUsingBlock:^(NSString *key, id<OHHTTPStubsDescriptor> stub, BOOL *stop) {
        if ([key hasPrefix:@"stub-"]) {
            [keysToRemove addObject:key];
            [OHHTTPStubs removeStub:stub];
        }
    }];

    self.stubsToRemoveAfterCount = [NSCountedSet set];
    [self.activeStubs removeObjectsForKeys:keysToRemove];
    
    return @"YES";
}

#pragma mark - Request Monitor Commands

- (NSString *)commandMonitorPathThathMatchesRegex:(GCDWebServerRequest *)tunnelRequest
{
    NSString *reqId = nil;

    NSString *stubId = [self identifierForStubRequest:tunnelRequest];
    if (self.activeStubs[stubId]) {
        NSLog(@"[UITestTunnelServer] Warning existing stub request found for monitor request, skipping");
        return nil;
    }
    
    if ([self validMonitorRequest:tunnelRequest]) {
        NSData *responseData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelProxyQueryRuleKey] options:0];
        NSString *regexPattern = [NSKeyedUnarchiver unarchiveObjectWithData:responseData];

        reqId = [SBTProxyURLProtocol proxyRequestsWithRegex:regexPattern delayResponse:0.0 responseBlock:^(NSURLRequest *request, NSURLRequest *originalRequest, NSHTTPURLResponse *response, NSData *responseData, NSTimeInterval requestTime) {
            NSAssert([NSThread isMainThread], @"Should be main thread"); // synchronize using main thread
            SBTMonitoredNetworkRequest *monitoredRequest = [[SBTMonitoredNetworkRequest alloc] init];
            
            monitoredRequest.timestamp = [[NSDate date] timeIntervalSinceReferenceDate];
            monitoredRequest.requestTime = requestTime;
            monitoredRequest.request = request;
            monitoredRequest.originalRequest = originalRequest;
            
            monitoredRequest.response = response;
            
            monitoredRequest.responseData = responseData;
            
            [self.monitoredRequests addObject:monitoredRequest];
        }];
    }
    
    return reqId;
}

- (NSString *)commandMonitorPathThathContainsQueryParams:(GCDWebServerRequest *)tunnelRequest
{
    NSString *reqId = nil;
    
    NSString *stubId = [self identifierForStubRequest:tunnelRequest];
    if (self.activeStubs[stubId]) {
        NSLog(@"[UITestTunnelServer] Warning existing stub request found for monitor request, skipping");
        return nil;
    }
    
    if ([self validMonitorRequest:tunnelRequest]) {
        NSData *responseData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelProxyQueryRuleKey] options:0];
        NSArray<NSString *> *queries = [NSKeyedUnarchiver unarchiveObjectWithData:responseData];
        
        reqId = [SBTProxyURLProtocol proxyRequestsWithQueryParams:queries delayResponse:0.0 responseBlock:^(NSURLRequest *request, NSURLRequest *originalRequest, NSHTTPURLResponse *response, NSData *responseData, NSTimeInterval requestTime) {
            NSAssert([NSThread isMainThread], @"Should be main thread"); // synchronize using main thread
            SBTMonitoredNetworkRequest *monitoredRequest = [[SBTMonitoredNetworkRequest alloc] init];
            
            monitoredRequest.timestamp = [[NSDate date] timeIntervalSinceReferenceDate];
            monitoredRequest.requestTime = requestTime;
            monitoredRequest.request = request;
            monitoredRequest.originalRequest = originalRequest;
            
            monitoredRequest.response = response;
            
            monitoredRequest.responseData = responseData;
            
            [self.monitoredRequests addObject:monitoredRequest];
        }];
    }
    
    return reqId;
}

- (NSString *)commandMonitorRemove:(GCDWebServerRequest *)tunnelRequest
{
    NSData *responseData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelStubQueryRuleKey] options:0];
    NSString *reqId = [NSKeyedUnarchiver unarchiveObjectWithData:responseData];

    return [SBTProxyURLProtocol proxyRequestsRemoveWithId:reqId] ? @"YES" : @"NO";
}

- (NSString *)commandMonitorsRemoveAll:(GCDWebServerRequest *)tunnelRequest
{
    [SBTProxyURLProtocol proxyRequestsRemoveAll];
    
    return @"YES";
}

- (NSString *)commandMonitorPeek:(GCDWebServerRequest *)tunnelRequest
{
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    __block NSString *ret = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // we use main thread to synchronize access to self.monitoredRequests
        NSArray *requestsToPeek = [self.monitoredRequests copy];
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:requestsToPeek];
        if (data) {
            ret = [data base64EncodedStringWithOptions:0];
        }
        dispatch_semaphore_signal(sem);
    });
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return ret;
}

- (NSString *)commandMonitorFlush:(GCDWebServerRequest *)tunnelRequest
{
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    __block NSString *ret = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // we use main thread to synchronize access to self.monitoredRequests
        NSArray *requestsToFlush = [self.monitoredRequests copy];
        self.monitoredRequests = [NSMutableArray array];
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:requestsToFlush];
        if (data) {
            ret = [data base64EncodedStringWithOptions:0];
        }
        dispatch_semaphore_signal(sem);
    });
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return ret;
}

#pragma mark - Throttle Monitor Commands

- (NSString *)commandThrottlePathThathMatchesRegex:(GCDWebServerRequest *)tunnelRequest
{
    NSString *reqId = nil;
    
    NSString *stubId = [self identifierForStubRequest:tunnelRequest];
    if (self.activeStubs[stubId]) {
        NSLog(@"[UITestTunnelServer] Warning existing stub request found for monitor request, skipping");
        return nil;
    }
    
    if ([self validThrottleRequest:tunnelRequest]) {
        NSData *responseData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelProxyQueryRuleKey] options:0];
        NSString *regexPattern = [NSKeyedUnarchiver unarchiveObjectWithData:responseData];
        NSTimeInterval responseDelayTime = [tunnelRequest.parameters[SBTUITunnelProxyQueryResponseTimeKey] doubleValue];
        
        reqId = [SBTProxyURLProtocol proxyRequestsWithRegex:regexPattern delayResponse:responseDelayTime responseBlock:nil];
    }
    
    return reqId;
}

- (NSString *)commandThrottlePathThathContainsQueryParams:(GCDWebServerRequest *)tunnelRequest
{
    NSString *reqId = nil;
    
    NSString *stubId = [self identifierForStubRequest:tunnelRequest];
    if (self.activeStubs[stubId]) {
        NSLog(@"[UITestTunnelServer] Warning existing stub request found for monitor request, skipping");
        return nil;
    }
    
    if ([self validThrottleRequest:tunnelRequest]) {
        NSData *responseData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelProxyQueryRuleKey] options:0];
        NSArray<NSString *> *queries = [NSKeyedUnarchiver unarchiveObjectWithData:responseData];
        NSTimeInterval responseDelayTime = [tunnelRequest.parameters[SBTUITunnelProxyQueryResponseTimeKey] doubleValue];
        
        reqId = [SBTProxyURLProtocol proxyRequestsWithQueryParams:queries delayResponse:responseDelayTime responseBlock:nil];
    }
    
    return reqId;
}

- (NSString *)commandThrottleRemove:(GCDWebServerRequest *)tunnelRequest
{
    NSData *responseData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelStubQueryRuleKey] options:0];
    NSString *reqId = [NSKeyedUnarchiver unarchiveObjectWithData:responseData];
    
    return [SBTProxyURLProtocol proxyRequestsRemoveWithId:reqId] ? @"YES" : @"NO";
}

- (NSString *)commandThrottlesRemoveAll:(GCDWebServerRequest *)tunnelRequest
{
    [SBTProxyURLProtocol proxyRequestsRemoveAll];
    
    return @"YES";
}

#pragma mark - NSUSerDefaults Commands

- (NSString *)commandNSUserDefaultsSetObject:(GCDWebServerRequest *)tunnelRequest
{
    NSString *objKey = tunnelRequest.parameters[SBTUITunnelObjectKeyKey];
    NSData *objData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelObjectKey] options:0];
    id obj = [NSKeyedUnarchiver unarchiveObjectWithData:objData];
    
    if (objKey) {
        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:objKey];
        return [[NSUserDefaults standardUserDefaults] synchronize] ? @"YES" : @"NO";
    }
    
    return @"NO";
}

- (NSString *)commandNSUserDefaultsRemoveObject:(GCDWebServerRequest *)tunnelRequest
{
    NSString *objKey = tunnelRequest.parameters[SBTUITunnelObjectKeyKey];
    
    if (objKey) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:objKey];
        return [[NSUserDefaults standardUserDefaults] synchronize] ? @"YES" : @"NO";
    }
    
    return @"NO";
}

- (NSString *)commandNSUserDefaultsObject:(GCDWebServerRequest *)tunnelRequest
{
    NSString *objKey = tunnelRequest.parameters[SBTUITunnelObjectKeyKey];
    
    NSObject *obj = [[NSUserDefaults standardUserDefaults] objectForKey:objKey];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:obj];
    if (data) {
        return [data base64EncodedStringWithOptions:0];
    }
    
    return nil;
}

- (NSString *)commandNSUserDefaultsReset:(GCDWebServerRequest *)tunnelRequest
{
    resetUserDefaults();
    
    return @"YES";
}

#pragma mark - Keychain Commands

- (NSString *)commandKeychainSetObject:(GCDWebServerRequest *)tunnelRequest
{
    NSString *objKey = tunnelRequest.parameters[SBTUITunnelObjectKeyKey];
    NSData *objData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelObjectKey] options:0];
    id obj = [NSKeyedUnarchiver unarchiveObjectWithData:objData];
    
    if (obj && objKey) {
        return [[FXKeychain defaultKeychain] setObject:obj forKey:objKey] ? @"YES" : @"NO";
    }
    
    return @"NO";
}

- (NSString *)commandKeychainRemoveObject:(GCDWebServerRequest *)tunnelRequest
{
    NSString *objKey = tunnelRequest.parameters[SBTUITunnelObjectKeyKey];
    
    if (objKey) {
        return [[FXKeychain defaultKeychain] removeObjectForKey:objKey] ? @"YES" : @"NO";
    }
    
    return @"NO";
}

- (NSString *)commandKeychainObject:(GCDWebServerRequest *)tunnelRequest
{
    NSString *objKey = tunnelRequest.parameters[SBTUITunnelObjectKeyKey];

    NSObject *obj = [[FXKeychain defaultKeychain] objectForKey:objKey];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:obj];
    if (data) {
        return [data base64EncodedStringWithOptions:0];
    }
    
    return nil;
}

- (NSString *)commandKeychainReset:(GCDWebServerRequest *)tunnelRequest
{
    deleteAllKeysForSecClass(kSecClassGenericPassword);
    deleteAllKeysForSecClass(kSecClassInternetPassword);
    deleteAllKeysForSecClass(kSecClassCertificate);
    deleteAllKeysForSecClass(kSecClassKey);
    deleteAllKeysForSecClass(kSecClassIdentity);
    
    return @"YES";
}

#pragma mark - Copy Commands

- (NSString *)commandUpload:(GCDWebServerRequest *)tunnelRequest
{
    NSData *fileData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelUploadDataKey] options:0];
    NSString *destPath = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelUploadDestPathKey] options:0]];
    NSSearchPathDirectory basePath = [tunnelRequest.parameters[SBTUITunnelUploadBasePathKey] intValue];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(basePath, NSUserDomainMask, YES);
    NSString *path = [[paths firstObject] stringByAppendingPathComponent:destPath];
    
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        
        if (error) {
            return @"NO";
        }
    }
    
    [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent]
                              withIntermediateDirectories:YES
                                               attributes:nil error:&error];
    if (error) {
        return @"NO";
    }

    
    return [fileData writeToFile:path atomically:YES] ? @"YES" : @"NO";
}

- (NSString *)commandDownload:(GCDWebServerRequest *)tunnelRequest
{
    NSString *srcPath = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelDownloadPathKey] options:0]];
    NSSearchPathDirectory basePath = [tunnelRequest.parameters[SBTUITunnelDownloadBasePathKey] intValue];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(basePath, NSUserDomainMask, YES);
    NSString *path = [[paths firstObject] stringByAppendingPathComponent:srcPath];
    
    NSData *fileData = [NSData dataWithContentsOfFile:path];
    
    return [fileData base64EncodedStringWithOptions:0];
}

#pragma mark - Other Commands 

- (NSString *)commandSetUIAnimations:(GCDWebServerRequest *)tunnelRequest
{
    BOOL enableAnimations = [tunnelRequest.parameters[SBTUITunnelObjectKey] boolValue];
    
    // Replacing [UIView setAnimationsEnabled:] as per
    // https://pspdfkit.com/blog/2016/running-ui-tests-with-ludicrous-speed/
    UIApplication.sharedApplication.keyWindow.layer.speed = enableAnimations ? 1 : 100;
    
    return @"YES";
}

- (NSString *)commandShutDown:(GCDWebServerRequest *)tunnelRequest
{
    dispatch_async(self.commandDispatchQueue, ^{
         [self.server stop];
    });
    
    return @"YES";
}

- (NSString *)commandStartupCompleted:(GCDWebServerRequest *)tunnelRequest
{
    self.startupCommandsCompleted = YES;
    
    return @"YES";
}

#pragma mark - Helper Methods

- (void)processStartupCommandsIfNeeded
{
    if ([[NSProcessInfo processInfo].arguments containsObject:SBTUITunneledApplicationLaunchOptionHasStartupCommands]) {
        self.startupCommandsCompleted = NO;
        while (!self.startupCommandsCompleted) {
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
        NSLog(@"[UITestTunnelServer] Startup commands completed");
    }
}

- (void)processLaunchOptionsIfNeeded
{
    if ([[NSProcessInfo processInfo].arguments containsObject:SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
        deleteAppData();
        [self commandNSUserDefaultsReset:nil];
        [self commandKeychainReset:nil];
    }
    if ([[NSProcessInfo processInfo].arguments containsObject:SBTUITunneledApplicationLaunchOptionAuthorizeLocation]) {
        // https://gist.github.com/daniel-beard/8238e12afd926a234813
        SEL selector = NSSelectorFromString(@"setAuthorizationStatus:forBundleIdentifier:");
        NSMethodSignature *methodSignature = [CLLocationManager methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.selector = selector;
        
        CLAuthorizationStatus status = kCLAuthorizationStatusAuthorizedAlways;
        NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
        
        [invocation setArgument:&status atIndex:2];
        [invocation setArgument:&identifier atIndex:3];
        [invocation invokeWithTarget:[CLLocationManager class]];
    }
}

- (NSString *)identifierForStubRequest:(GCDWebServerRequest *)tunnelRequest
{
    NSArray<NSString *> *components = @[tunnelRequest.parameters[SBTUITunnelStubQueryRuleKey]];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:components options:NSJSONWritingPrettyPrinted error:&error];

    if (!jsonData || error) {
        NSLog(@"[UITestTunnelServer] Failed to create identifierForStubRequest");
        return nil;
    }
    
    return [@"stub-" stringByAppendingString:[[jsonData SHA1] base64EncodedStringWithOptions:0]];
}

- (OHHTTPStubsResponse *)responseForStubRequest:(GCDWebServerRequest *)tunnelRequest withStubId:(NSString *)stubId
{
    if ([self.stubsToRemoveAfterCount containsObject:stubId]) {
        [self.stubsToRemoveAfterCount removeObject:stubId];
        
        if ([self.stubsToRemoveAfterCount countForObject:stubId] == 0) {
            [OHHTTPStubs removeStub:self.activeStubs[stubId]]; // next time it won't fire
            
            [self.activeStubs removeObjectForKey:stubId];
        }
    }

    NSData *responseArchivedData = [[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelStubQueryReturnDataKey] options:0];
    NSDictionary<NSString *, NSObject *> *responseDict = [NSKeyedUnarchiver unarchiveObjectWithData:responseArchivedData];
    
    NSError *error = nil;
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:responseDict options:NSJSONWritingPrettyPrinted error:&error];
    if (!responseData || error) {
        NSLog(@"[UITestTunnelServer] serialize response data");
        return nil;
    }
    
    OHHTTPStubsResponse *response = [OHHTTPStubsResponse responseWithData:responseData statusCode:[tunnelRequest.parameters[SBTUITunnelStubQueryReturnCodeKey] intValue] headers:@{@"Content-Type": @"application/json"}];
    
    NSTimeInterval responseTime = [tunnelRequest.parameters[SBTUITunnelStubQueryResponseTimeKey] doubleValue];
    
    return [response responseTime:responseTime];
}

- (BOOL)validStubRequest:(GCDWebServerRequest *)tunnelRequest
{
    if (!tunnelRequest.parameters[SBTUITunnelStubQueryReturnCodeKey] ||
        ![[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelStubQueryRuleKey] options:0] ||
        ![[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelStubQueryReturnDataKey] options:0]) {
        NSLog(@"[UITestTunnelServer] Invalid stubRequest received!");
        
        return NO;
    }
    
    return YES;
}

- (BOOL)validMonitorRequest:(GCDWebServerRequest *)tunnelRequest
{
    if (![[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelProxyQueryRuleKey] options:0]) {
        NSLog(@"[UITestTunnelServer] Invalid monitorRequest received!");
        
        return NO;
    }
    
    return YES;
}

- (BOOL)validThrottleRequest:(GCDWebServerRequest *)tunnelRequest
{
    if (tunnelRequest.parameters[SBTUITunnelProxyQueryResponseTimeKey] != nil && ![[NSData alloc] initWithBase64EncodedString:tunnelRequest.parameters[SBTUITunnelProxyQueryRuleKey] options:0]) {
        NSLog(@"[UITestTunnelServer] Invalid throttleRequest received!");
        
        return NO;
    }
    
    return YES;
}


#pragma mark - Helper Functions

// https://gist.github.com/michalzelinka/67adfa0142767575194f
void deleteAppData() {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *folders = @[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject],
                                     [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject],
                                     [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject],
                                     NSTemporaryDirectory()];
    
    NSError *error = nil;
    for (NSString *folder in folders) {
        for (NSString *file in [fm contentsOfDirectoryAtPath:folder error:&error]) {
            [fm removeItemAtPath:[folder stringByAppendingPathComponent:file] error:&error];
        }
    }
}

void resetUserDefaults() {
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [NSUserDefaults resetStandardUserDefaults];
}

// http://stackoverflow.com/a/26191925/574449
void (^deleteAllKeysForSecClass)(CFTypeRef) = ^(CFTypeRef secClass) {
    id dict = @{(__bridge id)kSecClass: (__bridge id)secClass};
    SecItemDelete((__bridge CFDictionaryRef) dict);
};

@end

#endif
