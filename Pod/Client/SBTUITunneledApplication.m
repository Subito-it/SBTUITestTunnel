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

#import "SBTUITunneledApplication.h"
#import "NSString+SwiftDemangle.h"
#include <ifaddrs.h>
#include <arpa/inet.h>


const NSTimeInterval SBTUITunneledApplicationDefaultTimeout = 30.0;
const uint16_t SBTUITunneledApplicationDefaultPort = 8666;

// it would have been more elegant to add a category on NSNetService, however Xcode 7.3 doesn't allow to do so
static NSString *localIpAddress(void)
{
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if (temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    
    return address;
}

static NSString *ipAddress(NSNetService *service)
{
    char addressBuffer[INET6_ADDRSTRLEN];
    
    for (NSData *data in service.addresses) {
        memset(addressBuffer, 0, INET6_ADDRSTRLEN);
        
        typedef union {
            struct sockaddr sa;
            struct sockaddr_in ipv4;
            struct sockaddr_in6 ipv6;
        } ip_socket_address;
        
        ip_socket_address *socketAddress = (ip_socket_address *)[data bytes];
        
        if (socketAddress && (socketAddress->sa.sa_family == AF_INET || socketAddress->sa.sa_family == AF_INET6)) {
            const char *addressStr = inet_ntop(
                                               socketAddress->sa.sa_family,
                                               (socketAddress->sa.sa_family == AF_INET ? (void *)&(socketAddress->ipv4.sin_addr) : (void *)&(socketAddress->ipv6.sin6_addr)),
                                               addressBuffer,
                                               sizeof(addressBuffer));
            
            int port = ntohs(socketAddress->sa.sa_family == AF_INET ? socketAddress->ipv4.sin_port : socketAddress->ipv6.sin6_port);
            
            if (addressStr && port) {
                // further workaround for http://www.openradar.me/23048120
                NSString *localAddress = localIpAddress();
                NSString *remoteAddress = [NSString stringWithCString:addressStr encoding:NSUTF8StringEncoding];

                NSString *validAddressRegex = @"^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
                NSPredicate *validAddressPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", validAddressRegex];

                if ([validAddressPredicate evaluateWithObject:remoteAddress]) {
                    return [localAddress isEqualToString:remoteAddress] ? @"127.0.0.1" : remoteAddress;
                }
            }
        }
    }
    
    return nil;
}

@interface SBTUITunneledApplication() <NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (nonatomic, strong) NSNetServiceBrowser *bonjourBrowser;
@property (nonatomic, strong) NSString *bonjourName;
@property (nonatomic, assign) NSTimeInterval connectionTimeout;
@property (nonatomic, assign) NSUInteger remotePort;
@property (nonatomic, strong) NSNetService *remoteService;
@property (nonatomic, strong) NSString *remoteHost;
@property (nonatomic, assign) NSInteger remoteHostsFound;
@property (nonnull, strong) NSMutableArray *stubOnceIds;

@property (nonatomic, strong) dispatch_semaphore_t bonjourSemaphore;

@end

@implementation SBTUITunneledApplication

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _bonjourBrowser = [[NSNetServiceBrowser alloc] init];
        _bonjourBrowser.delegate = self;
        // create a unique bonjourName (must be less than 63 characters)
        _bonjourName = [NSString stringWithFormat:@"com.subito.test.%d.%.0f", [NSProcessInfo processInfo].processIdentifier, (double)(CFAbsoluteTimeGetCurrent() * 100000)];
        _connectionTimeout = SBTUITunneledApplicationDefaultTimeout;
        _remotePort = SBTUITunneledApplicationDefaultPort;
        _remoteHostsFound = 0;
        _bonjourSemaphore = dispatch_semaphore_create(0);
    }
    
    return self;
}

- (void)terminate
{
    if (!self.ready) {
        return;
    }
    self.remoteHost = nil;
    self.remotePort = 0;
    
    [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandShutDown params:nil];
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
    self.launchArguments = options;

    if (startupBlock) {
        NSMutableArray *launchArguments = [self.launchArguments mutableCopy];
        [launchArguments addObject:SBTUITunneledApplicationLaunchOptionHasStartupCommands];
        self.launchArguments = launchArguments;
    }
    
    self.launchEnvironment = @{SBTUITunneledApplicationLaunchEnvironmentBonjourNameKey: self.bonjourName,
                               SBTUITunneledApplicationLaunchEnvironmentRemotePortKey: [@(_remotePort) stringValue]};
    
    [self.bonjourBrowser searchForServicesOfType:@"_http._tcp" inDomain:@""];
    
    __block BOOL startupBlockCompleted = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // 1 UI Test: (main thread) request app launch
            // 1 App: (main thread) GCD server is fired up and app will lock until the SBTUITunneledApplicationCommandStartupCommandsCompleted (if any)
            // 2 UI Test: (main thread) lock until startupBlock is completed
            // 2 UI Test: (background thread) bonjour delegates (here) will trigger once the GCD server is up
            // 3 UI Test: (background thread!) self.bonjourSemaphore is signalled and startup Block is executed
            [self launch];
        });
        
        dispatch_semaphore_wait(self.bonjourSemaphore, DISPATCH_TIME_FOREVER);
        
        if (startupBlock) {
            startupBlock(); // this will eventually add some commands in the startup command queue
            
            [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStartupCommandsCompleted params:@{}];
        }
        startupBlockCompleted = YES;
    });
    
    NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    while (!startupBlockCompleted) {
        // NSNetServiceBrowserDelegate, NSNetServiceDelegate delegate methods are dispatched on main thread
        [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        
        if (CFAbsoluteTimeGetCurrent() - start > self.connectionTimeout) {
            NSAssert(NO, @"[SBTUITestTunnel] could not connect to client app. Did you launch the bridge on the app?");
            [self terminate];
            return;
        }
    }
}

#pragma mark - Stub Commands

- (NSString *)stubRequestsWithRegex:(NSString *)regexPattern returnJsonDictionary:(NSDictionary<NSString *, NSObject *> *)json returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubQueryRuleKey: [self base64SerializeObject:regexPattern],
                                                     SBTUITunnelStubQueryReturnDataKey: [self base64SerializeObject:json],
                                                     SBTUITunnelStubQueryReturnCodeKey: [@(code) stringValue],
                                                     SBTUITunnelStubQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubPathThatMatchesRegex params:params];
}

- (NSString *)stubRequestsWithQueryParams:(NSArray<NSString *> *)queryParams returnJsonDictionary:(NSDictionary<NSString *, NSObject *> *)json returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubQueryRuleKey: [self base64SerializeObject:queryParams],
                                                     SBTUITunnelStubQueryReturnDataKey: [self base64SerializeObject:json],
                                                     SBTUITunnelStubQueryReturnCodeKey: [@(code) stringValue],
                                                     SBTUITunnelStubQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubPathThatContainsQueryParams params:params];
}

- (NSString *)stubRequestsWithRegex:(NSString *)regexPattern returnJsonNamed:(NSString *)jsonFilename returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime
{
    return [self stubRequestsWithRegex:regexPattern returnJsonDictionary:[self dictionaryFromJSONInBundle:jsonFilename] returnCode:code responseTime:responseTime];
}

- (NSString *)stubRequestsWithQueryParams:(NSArray<NSString *> *)queryParams returnJsonNamed:(NSString *)jsonFilename returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime
{
    return [self stubRequestsWithQueryParams:queryParams returnJsonDictionary:[self dictionaryFromJSONInBundle:jsonFilename] returnCode:code responseTime:responseTime];
}

#pragma mark - Stub And Remove Commands

- (BOOL)stubRequestsWithRegex:(NSString *)regexPattern returnJsonDictionary:(NSDictionary<NSString *, NSObject *> *)json returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime removeAfterIterations:(NSUInteger)iterations
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubQueryRuleKey: [self base64SerializeObject:regexPattern],
                                                     SBTUITunnelStubQueryReturnDataKey: [self base64SerializeObject:json],
                                                     SBTUITunnelStubQueryReturnCodeKey: [@(code) stringValue],
                                                     SBTUITunnelStubQueryIterations: [@(iterations) stringValue],
                                                     SBTUITunnelStubQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationcommandStubAndRemovePathThatMatchesRegex params:params] boolValue];
}

- (BOOL)stubRequestsWithQueryParams:(NSArray<NSString *> *)queryParams returnJsonDictionary:(NSDictionary<NSString *, NSObject *> *)json returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime removeAfterIterations:(NSUInteger)iterations
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubQueryRuleKey: [self base64SerializeObject:queryParams],
                                                     SBTUITunnelStubQueryReturnDataKey: [self base64SerializeObject:json],
                                                     SBTUITunnelStubQueryReturnCodeKey: [@(code) stringValue],
                                                     SBTUITunnelStubQueryIterations: [@(iterations) stringValue],
                                                     SBTUITunnelStubQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationcommandStubAndRemovePathThatContainsQueryParams params:params] boolValue];
}

- (BOOL)stubRequestsWithRegex:(NSString *)regexPattern returnJsonNamed:(NSString *)jsonFilename returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime removeAfterIterations:(NSUInteger)iterations
{
    return [self stubRequestsWithRegex:regexPattern returnJsonDictionary:[self dictionaryFromJSONInBundle:jsonFilename] returnCode:code responseTime:responseTime removeAfterIterations:iterations];
}

- (BOOL)stubRequestsWithQueryParams:(NSArray<NSString *> *)queryParams returnJsonNamed:(NSString *)jsonFilename returnCode:(NSInteger)code responseTime:(NSTimeInterval)responseTime removeAfterIterations:(NSUInteger)iterations
{
    return [self stubRequestsWithQueryParams:queryParams returnJsonDictionary:[self dictionaryFromJSONInBundle:jsonFilename] returnCode:code responseTime:responseTime removeAfterIterations:iterations];
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

- (NSString *)monitorRequestsWithRegex:(NSString *)regexPattern
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey: [self base64SerializeObject:regexPattern]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorPathThatMatchesRegex params:params];
}

- (NSString *)monitorRequestsWithQueryParams:(NSArray<NSString *> *)queryParams
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubQueryRuleKey: [self base64SerializeObject:queryParams]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorPathThatContainsQueryParams params:params];
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

#pragma mark - Throttle Requests Commands

- (nullable NSString *)throttleRequestsWithRegex:(nonnull NSString *)regexPattern responseTime:(NSTimeInterval)responseTime;
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey: [self base64SerializeObject:regexPattern], SBTUITunnelProxyQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandThrottlePathThatMatchesRegex params:params];
}

- (nullable NSString *)throttleRequestsWithQueryParams:(nonnull NSArray<NSString *> *)queryParams responseTime:(NSTimeInterval)responseTime;
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubQueryRuleKey: [self base64SerializeObject:queryParams], SBTUITunnelProxyQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandThrottlePathThatContainsQueryParams params:params];
}

- (BOOL)throttleRequestRemoveWithId:(nonnull NSString *)reqId;
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey:[self base64SerializeObject:reqId]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandThrottleRemove params:params] boolValue];
}

- (BOOL)throttleRequestRemoveWithIds:(nonnull NSArray<NSString *> *)reqIds;
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

- (BOOL)userDefaultsSetObject:(NSObject *)object forKey:(NSString *)key
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

- (BOOL)keychainSetObject:(NSObject *)object forKey:(NSString *)key
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

#pragma mark - Copy Commands

- (BOOL)uploadItemAtPath:(NSString *)srcPath toPath:(NSString *)destPath relativeTo:(NSSearchPathDirectory)baseFolder
{
    NSData *data = [NSData dataWithContentsOfFile:srcPath];
    
    if (!data) {
        return NO;
    }
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelUploadDataKey: [self base64SerializeData:data],
                                                     SBTUITunnelUploadDestPathKey: [self base64SerializeObject:destPath ?: @""],
                                                     SBTUITunnelUploadBasePathKey: [@(baseFolder) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandUploadData params:params] boolValue];
}

- (NSData *)downloadItemFromPath:(NSString *)path relativeTo:(NSSearchPathDirectory)baseFolder
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelDownloadPathKey: [self base64SerializeObject:path ?: @""],
                                                     SBTUITunnelDownloadBasePathKey: [@(baseFolder) stringValue]};
    
    NSString *fileBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandDownloadData params:params];
    
    if (fileBase64) {
        return [[NSData alloc] initWithBase64EncodedString:fileBase64 options:0];
    }
    
    return nil;
}

#pragma mark - Other Commands

- (BOOL)setUserInterfaceAnimationsEnabled:(BOOL)enabled
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: [@(enabled) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandSetUserInterfaceAnimations params:params] boolValue];
}

#pragma mark - Bonjour Delegates

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    if (ipAddress(sender).length > 0 && sender.port > 0) {
        // for some reasons using hostname to contact the server during startupBlock doesn't work
        // we'll instead use the plain IP address which kinda works :-/
        self.remoteHost = ipAddress(sender);
        self.remotePort = sender.port;
        
        dispatch_semaphore_signal(self.bonjourSemaphore);
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.remoteService resolveWithTimeout:15.0];
        });
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
    if ([service.name isEqualToString:self.bonjourName] && !self.remoteService) {
        self.remoteService = service;
        self.remoteService.delegate = self;
        [self.remoteService resolveWithTimeout:15.0];
        self.remoteHostsFound++;
    }
}

#pragma mark - Helper Methods

- (BOOL)ready
{
    return self.remoteHost.length > 0 && self.remotePort > 0;
}

- (NSDictionary<NSString *, NSObject *> *)dictionaryFromJSONInBundle:(NSString *)jsonFilename
{
    NSString *jsonName = [jsonFilename stringByDeletingPathExtension];
    NSString *jsonExtension = [jsonFilename pathExtension];
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:jsonName ofType:jsonExtension]];
    
    if (!data) {
        data = [self dataFromFrameworksWithName:jsonFilename];
    }
    
    NSDictionary<NSString *, NSObject *> *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
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
//#warning objective-c frameworks TODO.
        }
    }
    
    return data;
}

- (NSString *)base64SerializeObject:(NSObject *)obj
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

- (NSString *)sendSynchronousRequestWithPath:(NSString *)path params:(NSDictionary<NSString *, NSString *> *)params
{
    if (self.ready) {
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
                NSAssert(NO, @"[SBTUITestTunnel] Failed to get http response");
                [self terminate];
            } else {
                NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                responseId = jsonData[SBTUITunnelResponseResultKey];
                
                NSAssert(((NSHTTPURLResponse *)response).statusCode == 200, @"[SBTUITestTunnel] Message sending failed");
            }
            
            dispatch_semaphore_signal(synchRequestSemaphore);
        }] resume];
        
        dispatch_semaphore_wait(synchRequestSemaphore, DISPATCH_TIME_FOREVER);
        
        return responseId;
    }
    
    return nil;
}

@end

#endif
