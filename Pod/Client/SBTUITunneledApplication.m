// SBTUITunneledApplication.m
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
    #ifndef ENABLE_UITUNNEL 
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

#import "SBTUITunneledApplication.h"
#import "NSString+SwiftDemangle.h"
#import "NSURLRequest+SBTUITestTunnelMatch.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

const NSTimeInterval SBTUITunneledApplicationDefaultTimeout = 30.0;

const NSString *SBTUITunnelJsonMimeType = @"application/json";

@interface SBTUITunneledApplication()

@property (nonatomic, assign) NSTimeInterval connectionTimeout;
@property (nonatomic, assign) NSUInteger remotePort;
@property (nonatomic, strong) NSNetService *remoteService;
@property (nonatomic, strong) NSString *remoteHost;
@property (nonatomic, assign) NSInteger remoteHostsFound;
@property (nonatomic, strong) NSMutableArray *stubOnceIds;
@property (nonatomic, assign) BOOL startupBlockCompleted;
@property (nonatomic, strong) NSLock *startupBlockCompletedLock;

@end

@implementation SBTUITunneledApplication

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _connectionTimeout = SBTUITunneledApplicationDefaultTimeout;
        _remotePort = SBTUITunneledApplicationDefaultPort;
        _remoteHost = SBTUITunneledApplicationDefaultHost;
        _remoteHostsFound = 0;
        _startupBlockCompleted = NO;
        _startupBlockCompletedLock = [[NSLock alloc] init];
    }
    
    return self;
}

- (void)terminate
{
    [self.startupBlockCompletedLock lock];
    self.startupBlockCompleted = YES;
    [self.startupBlockCompletedLock unlock];
    
    [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandShutDown params:nil assertOnError:NO];
    
    [super terminate];
}

- (void)launchTunnel
{
    [self launchTunnelWithOptions:@[] startupBlock:nil];
}

- (void)launchTunnelWithStartupBlock:(void (^)(void))startupBlock;
{
    [self launchTunnelWithOptions:@[] startupBlock:startupBlock];
}

- (void)launchTunnelWithOptions:(NSArray<NSString *> *)options startupBlock:(void (^)(void))startupBlock
{
    NSMutableArray *launchArguments = [self.launchArguments mutableCopy];
    [launchArguments addObjectsFromArray:options];
    
    [launchArguments addObject:SBTUITunneledApplicationLaunchSignal];
    
    if (startupBlock) {
        [launchArguments addObject:SBTUITunneledApplicationLaunchOptionHasStartupCommands];
    }
    
    self.launchArguments = launchArguments;
    
    NSMutableDictionary<NSString *, NSString *> *launchEnvironment = [[NSMutableDictionary alloc] init];
    if (self.launchEnvironment) {
        // Add any previously defined entries in launchEnvironment
        [launchEnvironment addEntriesFromDictionary:self.launchEnvironment];
    }
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [weakSelf waitForServerUp];
        
        NSLog(@"[UITestTunnel] Server detected!");
        
        if (startupBlock) {
            startupBlock(); // this will eventually add some commands in the startup command queue
            
            [weakSelf sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStartupCommandsCompleted params:@{}];
        }
        
        [weakSelf.startupBlockCompletedLock lock];
        weakSelf.startupBlockCompleted = YES;
        [weakSelf.startupBlockCompletedLock unlock];
    });
    
    [self launch];
    
    for (int i = 0; i < 2.0 * self.connectionTimeout; i++) {
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        
        [self.startupBlockCompletedLock lock];
        BOOL localStartupBlockCompleted = self.startupBlockCompleted;
        [self.startupBlockCompletedLock unlock];
        
        if (localStartupBlockCompleted) {
            [self waitForServerReady];
            return;
        }
    }
    
    NSAssert(NO, @"[SBTUITestTunnel] could not connect to client app. Did you launch the bridge on the app?");
    [self terminate];
}

- (void)waitForServerUp
{
    const timeout = 30;
    int i = 0;
    for (i = 0; i < timeout; i++) {
        [NSThread sleepForTimeInterval:1.0];
        if ([self ping]) {
            return;
        }
    }
    
    NSAssert(NO, @"[SBTUITestTunnel] failed to connect to client app.");
    [self terminate];
}

- (void)waitForServerReady
{
    const timeout = 30;
    int i = 0;
    for (i = 0; i < timeout; i++) {
        [NSThread sleepForTimeInterval:1.0];
        if ([self isAppCruising]) {
            return;
        }
    }
    
    NSAssert(NO, @"[SBTUITestTunnel] failed waiting app to be ready");
    [self terminate];
}

#pragma mark - Ping Command

- (BOOL)ping
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandPing params:nil assertOnError:NO] isEqualToString:@"YES"];
}

#pragma mark - Kill Command

- (void)quit
{
    [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandQuit params:nil assertOnError:NO];
}

#pragma mark - Ready Command

- (BOOL)isAppCruising
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCruising params:nil] isEqualToString:@"YES"];
}


#pragma mark - Stub Commands

- (NSString *)stubRequestsMatching:(SBTRequestMatch *)match returnData:(NSData *)returnData contentType:(NSString *)contentType returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubQueryRuleKey: [self base64SerializeObject:match],
                                                     SBTUITunnelStubQueryReturnDataKey: [self base64SerializeObject:returnData],
                                                     SBTUITunnelStubQueryReturnCodeKey: [@(code) stringValue],
                                                     SBTUITunnelStubQueryMimeTypeKey: contentType,
                                                     SBTUITunnelStubQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubPathMatching params:params];
}

#pragma mark - Stub And Remove Commands

- (BOOL)stubRequestsMatching:(SBTRequestMatch *)match returnData:(NSData *)returnData contentType:(NSString *)contentType returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime removeAfterIterations:(NSUInteger)iterations
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubQueryRuleKey: [self base64SerializeObject:match],
                                                     SBTUITunnelStubQueryReturnDataKey: [self base64SerializeObject:returnData],
                                                     SBTUITunnelStubQueryReturnCodeKey: [@(code) stringValue],
                                                     SBTUITunnelStubQueryIterations: [@(iterations) stringValue],
                                                     SBTUITunnelStubQueryMimeTypeKey: contentType,
                                                     SBTUITunnelStubQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationcommandStubAndRemovePathMatching params:params] boolValue];
}

#pragma mark - Stub Commands JSON

- (NSString *)stubRequestsMatching:(SBTRequestMatch *)match returnJsonDictionary:(NSDictionary<NSString *, id> *)json returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubQueryRuleKey: [self base64SerializeObject:match],
                                                     SBTUITunnelStubQueryReturnDataKey: [self base64SerializeObject:json],
                                                     SBTUITunnelStubQueryReturnCodeKey: [@(code) stringValue],
                                                     SBTUITunnelStubQueryMimeTypeKey: SBTUITunnelJsonMimeType,
                                                     SBTUITunnelStubQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubPathMatching params:params];
}

- (NSString *)stubRequestsMatching:(SBTRequestMatch *)match returnJsonNamed:(NSString *)jsonFilename returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime
{
    return [self stubRequestsMatching:match returnJsonDictionary:[self dictionaryFromJSONInBundle:jsonFilename] returnCode:code responseTime:responseTime];
}

#pragma mark - Stub And Remove Commands JSON

- (BOOL)stubRequestsMatching:(SBTRequestMatch *)match returnJsonDictionary:(NSDictionary<NSString *, id> *)json returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime removeAfterIterations:(NSUInteger)iterations
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubQueryRuleKey: [self base64SerializeObject:match],
                                                     SBTUITunnelStubQueryReturnDataKey: [self base64SerializeObject:json],
                                                     SBTUITunnelStubQueryReturnCodeKey: [@(code) stringValue],
                                                     SBTUITunnelStubQueryIterations: [@(iterations) stringValue],
                                                     SBTUITunnelStubQueryMimeTypeKey: SBTUITunnelJsonMimeType,
                                                     SBTUITunnelStubQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationcommandStubAndRemovePathMatching params:params] boolValue];
}

- (BOOL)stubRequestsMatching:(SBTRequestMatch *)match returnJsonNamed:(NSString *)jsonFilename returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime removeAfterIterations:(NSUInteger)iterations
{
    return [self stubRequestsMatching:match returnJsonDictionary:[self dictionaryFromJSONInBundle:jsonFilename] returnCode:code responseTime:responseTime removeAfterIterations:iterations];
}

#pragma mark - Stub Remove Commands

- (BOOL)stubRequestsRemoveWithId:(NSString *)stubId
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubQueryRuleKey:[self base64SerializeObject:stubId]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandstubRequestsRemove params:params] boolValue];
}

- (BOOL)stubRequestsRemoveWithIds:(NSArray<NSString *> *)stubIds
{
    BOOL ret = YES;
    for (NSString *stubId in stubIds) {
        ret &= [self stubRequestsRemoveWithId:stubId];
    }
    
    return ret;
}

- (BOOL)stubRequestsRemoveAll
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationcommandStubRequestsRemoveAll params:nil] boolValue];
}

#pragma mark - Monitor Requests Commands

- (NSString *)monitorRequestsMatching:(SBTRequestMatch *)match
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey: [self base64SerializeObject:match]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorPathMatching params:params];
}

- (NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsPeekAll;
{
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationcommandMonitorPeek params:nil];
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData] ?: @[];
    }
    
    return nil;
}

- (NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsFlushAll;
{
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationcommandMonitorFlush params:nil];
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData] ?: @[];
    }
    
    return nil;
}

- (BOOL)monitorRequestRemoveWithId:(NSString *)reqId
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey:[self base64SerializeObject:reqId]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorRemove params:params] boolValue];
}

- (BOOL)monitorRequestRemoveWithIds:(NSArray<NSString *> *)reqIds
{
    BOOL ret = YES;
    for (NSString *reqId in reqIds) {
        ret &= [self monitorRequestRemoveWithId:reqId];
    }
    
    return ret;
}

- (BOOL)monitorRequestRemoveAll
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationcommandMonitorRemoveAll params:nil] boolValue];
}

#pragma mark - Asynchronously Wait for Requests Commands

- (void)waitForMonitoredRequestsMatching:(SBTRequestMatch *)match timeout:(NSTimeInterval)timeout completionBlock:(void (^)(BOOL timeout))completionBlock;
{
    [self waitForMonitoredRequestsMatching:match timeout:timeout iterations:1 completionBlock:completionBlock];
}

- (void)waitForMonitoredRequestsMatching:(SBTRequestMatch *)match timeout:(NSTimeInterval)timeout iterations:(NSUInteger)iterations completionBlock:(void (^)(BOOL timeout))completionBlock;
{
    [self waitForMonitoredRequestsWithMatchingBlock:^BOOL(SBTMonitoredNetworkRequest *request) {
        return [request.request matches:match];
    } timeout:timeout iterations:iterations completionBlock:completionBlock];
}

- (void)waitForMonitoredRequestsWithMatchingBlock:(BOOL(^)(SBTMonitoredNetworkRequest *))matchingBlock timeout:(NSTimeInterval)timeout iterations:(NSUInteger)iterations completionBlock:(void (^)(BOOL))completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
        NSTimeInterval start = CFAbsoluteTimeGetCurrent();
        
        BOOL timedout = NO;
        
        for(;;) {
            NSUInteger localIterations = iterations;
            NSArray<SBTMonitoredNetworkRequest *> *requests = [self monitoredRequestsPeekAll];
            
            for (SBTMonitoredNetworkRequest *request in requests) {
                if (matchingBlock(request)) {
                    if (--localIterations == 0) {
                        break;
                    }
                }
            }
            
            if (localIterations < 1) {
                break;
            } else if (CFAbsoluteTimeGetCurrent() - start > timeout) {
                timedout = YES;
                break;
            }
            
            [NSThread sleepForTimeInterval:0.5];
        }
        
        if (completionBlock) {
            completionBlock(timedout);
        }
    });
}

#pragma mark - Synchronously Wait for Requests Commands

- (BOOL)waitForMonitoredRequestsMatching:(SBTRequestMatch *)match timeout:(NSTimeInterval)timeout;
{
    return [self waitForMonitoredRequestsMatching:match timeout:timeout iterations:1];
}

- (BOOL)waitForMonitoredRequestsMatching:(SBTRequestMatch *)match timeout:(NSTimeInterval)timeout iterations:(NSUInteger)iterations;
{
    __block BOOL result = NO;
    __block BOOL done = NO;
    
    NSLock *doneLock = [[NSLock alloc] init];
    
    [self waitForMonitoredRequestsMatching:match timeout:timeout iterations:iterations completionBlock:^(BOOL didTimeout) {
        result = !didTimeout;
        
        [doneLock lock];
        done = YES;
        [doneLock unlock];
    }];
    
    for (;;) {
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        
        [doneLock lock];
        if (done) {
            [doneLock unlock];
            break;
        }
        [doneLock unlock];
    }
    
    return result;
}

#pragma mark - Throttle Requests Commands

- (NSString *)throttleRequestsMatching:(SBTRequestMatch *)match responseTime:(NSTimeInterval)responseTime;
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey: [self base64SerializeObject:match], SBTUITunnelProxyQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandThrottlePathMatching params:params];
}

- (BOOL)throttleRequestRemoveWithId:(NSString *)reqId;
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey:[self base64SerializeObject:reqId]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandThrottleRemove params:params] boolValue];
}

- (BOOL)throttleRequestRemoveWithIds:(NSArray<NSString *> *)reqIds;
{
    BOOL ret = YES;
    for (NSString *reqId in reqIds) {
        ret &= [self throttleRequestRemoveWithId:reqId];
    }
    
    return ret;
}

- (BOOL)throttleRequestRemoveAll
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationcommandThrottleRemoveAll params:nil] boolValue];
}

#pragma mark - NSUserDefaults Commands

- (BOOL)userDefaultsSetObject:(id)object forKey:(NSString *)key
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: key,
                                                     SBTUITunnelObjectKey: [self base64SerializeObject:object]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsSetObject params:params] boolValue];
}

- (BOOL)userDefaultsRemoveObjectForKey:(NSString *)key
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: key};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsRemoveObject params:params] boolValue];
}

- (id)userDefaultsObjectForKey:(NSString *)key
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: key};
    
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsObject params:params];
    
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
    }
    
    return nil;
}

- (BOOL)userDefaultsReset
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsReset params:nil] boolValue];
}

#pragma mark - Keychain Commands

- (BOOL)keychainSetObject:(id)object forKey:(NSString *)key
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: key,
                                                     SBTUITunnelObjectKey: [self base64SerializeObject:object]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandKeychainSetObject params:params] boolValue];
}

- (BOOL)keychainRemoveObjectForKey:(NSString *)key
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: key};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandKeychainRemoveObject params:params] boolValue];
}

- (id)keychainObjectForKey:(NSString *)key
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: key};
    
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandKeychainObject params:params];
    
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
    }
    
    return nil;
}

- (BOOL)keychainReset
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandKeychainReset params:nil] boolValue];
}

#pragma mark - NSBundle

- (nullable NSDictionary<NSString *, id> *)mainBundleInfoDictionary;
{
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMainBundleInfoDictionary params:nil];
    
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
    }
    
    return nil;
}

#pragma mark - Copy Commands

- (BOOL)uploadItemAtPath:(NSString *)srcPath toPath:(NSString *)destPath relativeTo:(NSSearchPathDirectory)baseFolder
{
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:srcPath]];
    
    if (!data) {
        return NO;
    }
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelUploadDataKey: [self base64SerializeData:data],
                                                     SBTUITunnelUploadDestPathKey: [self base64SerializeObject:destPath ?: @""],
                                                     SBTUITunnelUploadBasePathKey: [@(baseFolder) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandUploadData params:params] boolValue];
}

- (NSArray<NSData *> *)downloadItemsFromPath:(NSString *)path relativeTo:(NSSearchPathDirectory)baseFolder
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelDownloadPathKey: [self base64SerializeObject:path ?: @""],
                                                     SBTUITunnelDownloadBasePathKey: [@(baseFolder) stringValue]};
    
    NSString *itemsBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandDownloadData params:params];
    
    if (itemsBase64) {
        NSData *itemsData = [[NSData alloc] initWithBase64EncodedString:itemsBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:itemsData];
    }
    
    return nil;
}

#pragma mark - Custom Commands

- (id)performCustomCommandNamed:(NSString *)commandName object:(id)object
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelCustomCommandKey: commandName,
                                                     SBTUITunnelObjectKey: [self base64SerializeObject:object]};
    
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCustom params:params];
    
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
    }
    
    return nil;
}

#pragma mark - Other Commands

- (BOOL)setUserInterfaceAnimationsEnabled:(BOOL)enabled
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: [@(enabled) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandSetUserInterfaceAnimations params:params] boolValue];
}

- (BOOL)setUserInterfaceAnimationSpeed:(NSInteger)speed
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: [@(speed) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandSetUserInterfaceAnimationSpeed params:params] boolValue];
}

#pragma mark - Helper Methods

- (NSDictionary<NSString *, id> *)dictionaryFromJSONInBundle:(NSString *)jsonFilename
{
    NSString *jsonName = [jsonFilename stringByDeletingPathExtension];
    NSString *jsonExtension = [jsonFilename pathExtension];
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:jsonName ofType:jsonExtension]];
    
    if (!data) {
        data = [self dataFromFrameworksWithName:jsonFilename];
    }
    
    NSDictionary<NSString *, id> *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (!dict || error) {
        NSAssert(NO, @"[SBTUITestTunnel] Failed to deserialize json file %@", jsonFilename);
    }
    
    return dict;
}

- (NSData *)dataFromFrameworksWithName:(NSString *)filename
{
    NSString *name = [filename stringByDeletingPathExtension];
    NSString *extension = [filename pathExtension];
    
    NSData *data = nil;
    
    // find in frameworks extracting info from stacktrace
    // are we using frameworks? Swift?
    for (NSString *sourceString in [NSThread callStackSymbols]) {
        NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
        NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
        [array removeObject:@""];
        
        NSString *swiftClassName = [array[3] demangleSwiftClassName];
        
        if (swiftClassName) {
            data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:NSClassFromString(swiftClassName)] pathForResource:name ofType:extension]];
            
            if (data) {
                break;
            }
        } else {
            // #warning objective-c frameworks TODO.
        }
    }
    
    return data;
}

- (NSString *)base64SerializeObject:(id)obj
{
    NSData *objData = [NSKeyedArchiver archivedDataWithRootObject:obj];
    
    return [self base64SerializeData:objData];
}

- (NSString *)base64SerializeData:(NSData *)data
{
    if (!data) {
        NSAssert(NO, @"[SBTUITestTunnel] Failed to serialize object");
        [self terminate];
        return @"";
    } else {
        return [[data base64EncodedStringWithOptions:0] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    }
}

- (NSString *)sendSynchronousRequestWithPath:(NSString *)path params:(NSDictionary<NSString *, NSString *> *)params assertOnError:(BOOL)assertOnError
{
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%d/%@", self.remoteHost, (unsigned int)self.remotePort, path];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = nil;
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    
    NSMutableArray *queryItems = [NSMutableArray array];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
    }];
    components.queryItems = queryItems;
    
    if ([SBTUITunnelHTTPMethod isEqualToString:@"GET"]) {
        request = [NSMutableURLRequest requestWithURL:components.URL];
    } else if  ([SBTUITunnelHTTPMethod isEqualToString:@"POST"]) {
        request = [NSMutableURLRequest requestWithURL:url];
        
        request.HTTPBody = [components.query dataUsingEncoding:NSUTF8StringEncoding];
    }
    request.HTTPMethod = SBTUITunnelHTTPMethod;
    
    if (!request) {
        NSAssert(NO, @"[SBTUITestTunnel] Did fail to create url component");
        [self terminate];
        return nil;
    }
    
    dispatch_semaphore_t synchRequestSemaphore = dispatch_semaphore_create(0);
    
    NSURLSession *session = [NSURLSession sharedSession];
    __block NSString *responseId = nil;
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (![response isKindOfClass:[NSHTTPURLResponse class]]) {
            if (assertOnError) {
                NSLog(NO, @"[SBTUITestTunnel] Failed to get http response: %@", request);
                // [weakSelf terminate];
            }
        } else {
            NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            responseId = jsonData[SBTUITunnelResponseResultKey];
            
            if (assertOnError) {
                if (((NSHTTPURLResponse *)response).statusCode != 200) {
                    NSLog(@"[SBTUITestTunnel] Message sending failed: %@", request);
                }
            }
        }
        
        dispatch_semaphore_signal(synchRequestSemaphore);
    }] resume];
    
    dispatch_semaphore_wait(synchRequestSemaphore, DISPATCH_TIME_FOREVER);
    
    return responseId;
}

- (NSString *)sendSynchronousRequestWithPath:(NSString *)path params:(NSDictionary<NSString *, NSString *> *)params
{
    return [self sendSynchronousRequestWithPath:path params:params assertOnError:YES];
}

@end

#endif
