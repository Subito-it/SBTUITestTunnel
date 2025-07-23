// SBTUITestTunnelClient.m
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

@import XCTest;
@import SBTUITestTunnelCommon;

#import "include/SBTUITestTunnelClient.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <netdb.h>

const NSString *SBTUITunnelJsonMimeType = @"application/json";
#define kSBTUITestTunnelErrorDomain @"com.subito.sbtuitesttunnel.error"

@interface SBTUITestTunnelClient() <NSNetServiceDelegate, SBTIPCTunnel>
{
    BOOL _userInterfaceAnimationsEnabled;
    NSInteger _userInterfaceAnimationSpeed;
}

@property (nonatomic, weak) XCUIApplication *application;
@property (nonatomic, assign) NSInteger connectionPort;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) NSTimeInterval connectionTimeout;
@property (nonatomic, strong) NSMutableArray *stubOnceIds;
@property (nonatomic, strong) void (^startupBlock)(void);
@property (nonatomic, copy) NSArray<NSString *> *initialLaunchArguments;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *initialLaunchEnvironment;
@property (nonatomic, strong) NSString *(^connectionlessBlock)(NSString *, NSDictionary<NSString *, NSString *> *);
@property (nonatomic, assign) BOOL startupCompleted;
@property (nonatomic, strong) DTXIPCConnection* ipcConnection;
@property (nonatomic, strong) id<SBTIPCTunnel> ipcProxy;
@property (nonatomic, assign) NSTimeInterval launchStart;

@end

@implementation SBTUITestTunnelClient

static NSTimeInterval SBTUITunneledApplicationDefaultTimeout = 30.0;

- (instancetype)initWithApplication:(XCUIApplication *)application
{
    self = [super init];
    
    if (self) {
        _initialLaunchArguments = application.launchArguments;
        _initialLaunchEnvironment = application.launchEnvironment;
        _application = application;
        _userInterfaceAnimationsEnabled = YES;
        _userInterfaceAnimationSpeed = 1;
        
        [self resetInternalState];
    }
    
    return self;
}

- (void)resetInternalState
{
    self.application.launchArguments = self.initialLaunchArguments;
    self.application.launchEnvironment = self.initialLaunchEnvironment;

    self.startupBlock = nil;

    self.startupCompleted = NO;
    self.connected = NO;
    self.connectionPort = 0;
    self.connectionTimeout = SBTUITunneledApplicationDefaultTimeout;
}

- (void)shutDownWithError:(NSError *)error
{
    if (error) {
        NSLog(@"[SBTUITestTunnel] Shutting down with error: '%@'", error.localizedDescription);
    }

    [self resetInternalState];
    
    if ([self.delegate respondsToSelector:@selector(tunnelClient:didShutdownWithError:)]) {
        [self.delegate tunnelClient:self didShutdownWithError:error];
    }
}

- (void)shutDownWithErrorMessage:(NSString *)message code:(SBTUITestTunnelError)code
{
    NSError *error = [self.class errorWithCode:code
                                       message:message];
    [self shutDownWithError:error];
}

- (void)launchTunnel
{
    [self launchTunnelWithStartupBlock:nil];
}

- (void)launchTunnelWithStartupBlock:(void (^)(void))startupBlock
{
    NSAssert([NSThread isMainThread], @"This method should be invoked from main thread");
    
    self.launchStart = CFAbsoluteTimeGetCurrent();
    
    NSMutableArray *launchArguments = [self.application.launchArguments mutableCopy];
    [launchArguments addObject:SBTUITunneledApplicationLaunchSignal];

    if (startupBlock) {
        [launchArguments addObject:SBTUITunneledApplicationLaunchOptionHasStartupCommands];
    }

    self.startupBlock = startupBlock;
    self.application.launchArguments = launchArguments;
    
    NSMutableDictionary<NSString *, NSString *> *launchEnvironment = [self.application.launchEnvironment mutableCopy];
    
    BOOL useIPC;
    #if TARGET_OS_SIMULATOR
        NSBundle *bundle = [NSBundle bundleForClass:[SBTUITestTunnelClient class]];
        useIPC = !([[bundle objectForInfoDictionaryKey:@"SBTUITestTunnelDisableIPC"] boolValue]);
    #else
        useIPC = NO;
    #endif
    
    if (useIPC) {
        NSString *serviceIdentifier = [NSUUID UUID].UUIDString;
        self.ipcConnection = [[DTXIPCConnection alloc] initWithServiceName:[NSString stringWithFormat:@"com.subito.sbtuitesttunnel.ipc.%@", serviceIdentifier]];
        self.ipcConnection.remoteObjectInterface = [DTXIPCInterface interfaceWithProtocol:@protocol(SBTIPCTunnel)];
        self.ipcConnection.exportedInterface = [DTXIPCInterface interfaceWithProtocol:@protocol(SBTIPCTunnel)];
        self.ipcConnection.exportedObject = self;
            
        [self.ipcConnection resume];
        
        self.ipcProxy = [self.ipcConnection synchronousRemoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
            [self shutDownWithErrorMessage:[NSString stringWithFormat:@"[SBTUITestTunnelClient] Failed getting IPC proxy, %@", error.description] code:SBTUITestTunnelErrorLaunchFailed];
        }];
            
        launchEnvironment[SBTUITunneledApplicationLaunchEnvironmentIPCKey] = serviceIdentifier;
        self.application.launchEnvironment = launchEnvironment;
    } else {
        self.connectionPort = [SBTUITestTunnelNetworkUtility reserveSocketPort];
        NSLog(@"[SBTUITestTunnel] Resolving connection on port %ld", self.connectionPort);
        
        if (self.connectionPort < 0) {
            return [self shutDownWithErrorMessage:[NSString stringWithFormat:@"[SBTUItestTunnel] Failed finding open port, error: %ld", self.connectionPort] code:SBTUITestTunnelErrorLaunchFailed];
        }

        launchEnvironment[SBTUITunneledApplicationLaunchEnvironmentPortKey] = [NSString stringWithFormat: @"%ld", (long)self.connectionPort];
        self.application.launchEnvironment = launchEnvironment;
        
        __weak typeof(self)weakSelf = self;
        // Start polling the server with the choosen port
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [weakSelf waitForConnection];
            NSLog(@"[SBTUITestTunnel] HTTP tunnel did connect after, %fs", CFAbsoluteTimeGetCurrent() - self.launchStart);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.connected = YES;
                if (weakSelf.startupBlock) {
                    weakSelf.startupBlock();
                    NSLog(@"[SBTUITestTunnel] Did perform startupBlock");
                }
                
                NSAssert([NSThread isMainThread], @"We synch on main thread");
                weakSelf.startupCompleted = [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStartupCommandsCompleted params:@{}] isEqualToString:@"YES"];
            });
        });
    }
    
    [self.delegate tunnelClientIsReadyToLaunch:self];
    
    while (YES) {
        [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        
        if (CFAbsoluteTimeGetCurrent() - self.launchStart > SBTUITunneledApplicationDefaultTimeout) {
            return [self shutDownWithErrorMessage:[NSString stringWithFormat:@"[SBTUITestTunnel] Waiting for startup block completion timed out"] code:SBTUITestTunnelErrorLaunchFailed];
        }
        
        if (self.startupCompleted) {
            break;
        }
    }
    
    NSLog(@"[SBTUITestTunnel] Tunnel ready after %fs", CFAbsoluteTimeGetCurrent() - self.launchStart);
}

- (void)launchConnectionless:(NSString * (^)(NSString *, NSDictionary<NSString *, NSString *> *))command
{
    self.connectionlessBlock = command;
    [self shutDownWithError:nil];
}

- (void)terminate
{
    [self shutDownWithError:nil];
}

- (void)waitForConnection
{
    NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    while (CFAbsoluteTimeGetCurrent() - start < self.connectionTimeout) {
        char *hostname = "localhost";
        
        int sockfd;
        struct sockaddr_in serv_addr;
        struct hostent *server;
        
        sockfd = socket(AF_INET, SOCK_STREAM, 0);
        if (sockfd < 0) {
            return [self shutDownWithErrorMessage:@"Failed opening socket" code:SBTUITestTunnelErrorConnectionToApplicationFailed];
        }
        
        server = gethostbyname(hostname);
        if (server == NULL) {
            return [self shutDownWithErrorMessage:@"Invalid host" code:SBTUITestTunnelErrorConnectionToApplicationFailed];
        }
        
        bzero((char *) &serv_addr, sizeof(serv_addr));
        serv_addr.sin_family = AF_INET;
        bcopy((char *)server->h_addr,
              (char *)&serv_addr.sin_addr.s_addr,
              server->h_length);
        
        serv_addr.sin_port = htons(self.connectionPort);
        BOOL serverUp = connect(sockfd,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) >= 0;
        close(sockfd);
        
        if (serverUp && [self ping]) {
            return;
        } else {
            [NSThread sleepForTimeInterval:0.5];
        }
    }

    [self shutDownWithErrorMessage:@"Failed waiting for app to be ready" code:SBTUITestTunnelErrorConnectionToApplicationFailed];
}

// MARK: - SBTIPCTunnel

- (void)serverDidConnect:(id)sender
{
    while (!self.ipcConnection.isValid) {
        if (CFAbsoluteTimeGetCurrent() - self.launchStart > SBTUITunneledApplicationDefaultTimeout) {
            [self shutDownWithErrorMessage:@"[SBTUITestTunnel] IPC tunnel did fail to connect" code:SBTUITestTunnelErrorConnectionToApplicationFailed];
            return;
        }
            
        [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.connected = YES;

        NSLog(@"[SBTUITestTunnel] IPC tunnel did connect after, %fs", CFAbsoluteTimeGetCurrent() - weakSelf.launchStart);

        if (weakSelf.startupBlock) {
            weakSelf.startupBlock();
            NSLog(@"[SBTUITestTunnel] Did perform startupBlock");
        }
        
        weakSelf.startupCompleted = [[weakSelf sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStartupCommandsCompleted params:@{}] isEqualToString:@"YES"];

        NSLog(@"[SBTUITestTunnel] Tunnel ready after %fs", CFAbsoluteTimeGetCurrent() - weakSelf.launchStart);
    });
}

- (void)performCommandWithParameters:(NSDictionary *)parameters block:(void (^)(NSDictionary *))block {}

#pragma mark - Timeout

+ (void)setConnectionTimeout:(NSTimeInterval)timeout
{
    NSAssert(timeout > 5.0, @"[SBTUITestTunnel] Timeout too short!");
    SBTUITunneledApplicationDefaultTimeout = timeout;
}

#pragma mark - Ping Command

- (BOOL)ping
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandPing params:nil assertOnError:NO] isEqualToString:@"YES"];
}

#pragma mark - Quit Command

- (void)quit
{
    [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandQuit params:nil assertOnError:NO];
}

#pragma mark - Stub Commands

- (NSString *)stubRequestsMatching:(SBTRequestMatch *)match response:(SBTStubResponse *)response
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubMatchRuleKey: [self base64SerializeObject:match],
                                                     SBTUITunnelStubResponseKey: [self base64SerializeObject:response]
                                                     };
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubMatching params:params];
}

#pragma mark - Stub Remove Commands

- (BOOL)stubRequestsRemoveWithId:(NSString *)stubId
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubMatchRuleKey:[self base64SerializeObject:stubId]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubRequestsRemove params:params] boolValue];
}

- (BOOL)stubRequestsRemoveWithIds:(NSArray<NSString *> *)stubIds
{
    BOOL ret = YES;
    for (NSString *stubId in stubIds) {
        ret &= [self stubRequestsRemoveWithId:stubId];
    }
    
    return ret;
}

- (BOOL)stubRequestsRemoveWithRequestMatch:(nonnull SBTRequestMatch *)match
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelStubMatchRuleKey: [self base64SerializeObject:match]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubRequestsRemove params:params] isEqualToString:@"YES"];
}

- (BOOL)stubRequestsRemoveAll
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubRequestsRemoveAll params:nil] boolValue];
}

- (NSArray<SBTActiveStub *> *)stubRequestsAll
{
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubRequestsAll params:nil];
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];

        NSError *unarchiveError;
        NSSet *classes = [NSSet setWithObjects:[NSArray class], [SBTActiveStub class], nil];
        NSArray *result = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:objectData error:&unarchiveError];
        NSAssert(unarchiveError == nil, @"Error unarchiving NSArray of SBTActiveStub");

        return result ?: @[];
    }
    
    return @[];
}

#pragma mark - Rewrite Commands

- (NSString *)rewriteRequestsMatching:(SBTRequestMatch *)match rewrite:(SBTRewrite *)rewrite
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelRewriteMatchRuleKey: [self base64SerializeObject:match],
                                                     SBTUITunnelRewriteKey: [self base64SerializeObject:rewrite]
                                                     };
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandRewriteMatching params:params];
}

#pragma mark - Rewrite Remove Commands

- (BOOL)rewriteRequestsRemoveWithId:(NSString *)rewriteId
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelRewriteMatchRuleKey:[self base64SerializeObject:rewriteId]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandRewriteRequestsRemove params:params] boolValue];
}

- (BOOL)rewriteRequestsRemoveWithIds:(NSArray<NSString *> *)rewriteIds
{
    BOOL ret = YES;
    for (NSString *rewriteId in rewriteIds) {
        ret &= [self rewriteRequestsRemoveWithId:rewriteId];
    }
    
    return ret;
}

- (BOOL)rewriteRequestsRemoveAll
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandRewriteRequestsRemoveAll params:nil] boolValue];
}

#pragma mark - Monitor Requests Commands

- (NSString *)monitorRequestsMatching:(SBTRequestMatch *)match
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey: [self base64SerializeObject:match]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorMatching params:params];
}

- (NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsPeekAll
{
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorPeek params:nil];
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        NSError *unarchiveError;
        NSSet *classes = [NSSet setWithObjects:[NSArray class], [SBTMonitoredNetworkRequest class], nil];
        NSArray *result = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:objectData error:&unarchiveError];
        NSAssert(unarchiveError == nil, @"Error unarchiving NSArray of SBTMonitoredNetworkRequest");

        return result ?: @[];
    }
    
    return @[];
}

- (NSArray<SBTMonitoredNetworkRequest *> *)monitoredRequestsFlushAll
{
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorFlush params:nil];
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        NSError *unarchiveError;
        NSSet *classes = [NSSet setWithObjects:[NSArray class], [SBTMonitoredNetworkRequest class], nil];
        NSArray *result = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:objectData error:&unarchiveError];
        NSAssert(unarchiveError == nil, @"Error unarchiving NSArray of SBTMonitoredNetworkRequest");

        return result ?: @[];
    }
    
    return @[];
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
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMonitorRemoveAll params:nil] boolValue];
}

#pragma mark - Synchronously Wait for Requests Commands

- (BOOL)waitForMonitoredRequestsMatching:(SBTRequestMatch *)match timeout:(NSTimeInterval)timeout;
{
    return [self waitForMonitoredRequestsMatching:match timeout:timeout iterations:1];
}

- (BOOL)waitForMonitoredRequestsMatching:(SBTRequestMatch *)match timeout:(NSTimeInterval)timeout iterations:(NSUInteger)iterations;
{
    NSTimeInterval start = CFAbsoluteTimeGetCurrent();
    
    while (CFAbsoluteTimeGetCurrent() - start < timeout) {
        NSArray<SBTMonitoredNetworkRequest *> *requests = [self monitoredRequestsPeekAll];
        
        NSUInteger localIterations = iterations;
        for (SBTMonitoredNetworkRequest *request in requests) {
            if ([request matches:match]) {
                if (--localIterations == 0) {
                    return YES;
                }
            }
        }
        
        if (iterations == 0) {
            return localIterations == iterations;
        }
        
        [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }

    return NO;
}

#pragma mark - Throttle Requests Commands

- (NSString *)throttleRequestsMatching:(SBTRequestMatch *)match responseTime:(NSTimeInterval)responseTime;
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelProxyQueryRuleKey: [self base64SerializeObject:match], SBTUITunnelProxyQueryResponseTimeKey: [@(responseTime) stringValue]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandThrottleMatching params:params];
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
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandThrottleRemoveAll params:nil] boolValue];
}

#pragma mark - Cookie Block Requests Commands

- (NSString *)blockCookiesInRequestsMatching:(SBTRequestMatch *)match
{
    return [self blockCookiesInRequestsMatching:match activeIterations:0];
}

- (NSString *)blockCookiesInRequestsMatching:(SBTRequestMatch *)match activeIterations:(NSUInteger)activeIterations
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelCookieBlockMatchRuleKey: [self base64SerializeObject:match],
                                                     SBTUITunnelCookieBlockQueryIterationsKey: [@(activeIterations) stringValue]};
    
    return [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCookieBlockMatching params:params];
}

- (BOOL)blockCookiesRequestsRemoveWithId:(NSString *)reqId
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelCookieBlockMatchRuleKey:[self base64SerializeObject:reqId]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCookieBlockRemove params:params] boolValue];
}

- (BOOL)blockCookiesRequestsRemoveWithIds:(NSArray<NSString *> *)reqIds
{
    BOOL ret = YES;
    for (NSString *reqId in reqIds) {
        ret &= [self blockCookiesRequestsRemoveWithId:reqId];
    }
    
    return ret;
}

- (BOOL)blockCookiesRequestsRemoveAll
{
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCookieBlockRemoveAll params:nil] boolValue];
}

#pragma mark - NSUserDefaults Commands

- (BOOL)userDefaultsSetObject:(id)object forKey:(NSString *)key
{
    return [self userDefaultsSetObject:object forKey:key suiteName:@""];
}

- (BOOL)userDefaultsRemoveObjectForKey:(NSString *)key
{
    return [self userDefaultsRemoveObjectForKey:key suiteName:@""];
}

- (id)userDefaultsObjectForKey:(NSString *)key
{
    return [self userDefaultsObjectForKey:key suiteName:@""];
}

- (BOOL)userDefaultsReset
{
    return [self userDefaultsResetSuiteName:@""];
}

- (BOOL)userDefaultsRegisterDefaults:(NSDictionary *)dictionary
{
    return [self userDefaultsRegisterDefaults:dictionary suiteName:@""];
}

- (BOOL)userDefaultsSetObject:(id)object forKey:(NSString *)key suiteName:(NSString *)suiteName;
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: key,
                                                     SBTUITunnelObjectKey: [self base64SerializeObject:object],
                                                     SBTUITunnelUserDefaultSuiteNameKey: suiteName};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsSetObject params:params] boolValue];
}

- (BOOL)userDefaultsRemoveObjectForKey:(NSString *)key suiteName:(NSString *)suiteName;
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: key,
                                                     SBTUITunnelUserDefaultSuiteNameKey: suiteName};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsRemoveObject params:params] boolValue];
}

- (id)userDefaultsObjectForKey:(NSString *)key suiteName:(NSString *)suiteName;
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKeyKey: key,
                                                     SBTUITunnelUserDefaultSuiteNameKey: suiteName};
    
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsObject params:params];
    
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];

        // this can't switch to the non-deprecated NSSecureCoding method because the types aren't known ahead of time
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
        #pragma clang diagnostic pop
    }
    
    return nil;
}

- (BOOL)userDefaultsResetSuiteName:(NSString *)suiteName;
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelUserDefaultSuiteNameKey: suiteName};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsReset params:params] boolValue];
}

- (BOOL)userDefaultsRegisterDefaults:(NSDictionary *)dictionary suiteName:(NSString *)suiteName
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: [self base64SerializeObject:dictionary],
                                                     SBTUITunnelUserDefaultSuiteNameKey: suiteName};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNSUserDefaultsRegisterDefaults params:params] boolValue];
}

#pragma mark - NSBundle

- (NSDictionary<NSString *, id> *)mainBundleInfoDictionary;
{
    NSString *objectBase64 = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandMainBundleInfoDictionary params:nil];
    
    if (objectBase64) {
        NSData *objectData = [[NSData alloc] initWithBase64EncodedString:objectBase64 options:0];
        
        // this can't switch to the non-deprecated NSSecureCoding method because the types aren't known ahead of time
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
        #pragma clang diagnostic pop
    }
    
    return nil;
}

#pragma mark - Copy Commands

- (BOOL)uploadItemAtPath:(NSString *)srcPath toPath:(NSString *)destPath relativeTo:(NSSearchPathDirectory)baseFolder
{
    NSAssert(![srcPath hasPrefix:@"file:"], @"Call this methon passing srcPath using [NSURL path] not [NSURL absoluteString]!");
    
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

        NSError *unarchiveError;
        NSSet *classes = [NSSet setWithObjects:[NSArray class], [NSData class], nil];
        NSArray *result = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:itemsData error:&unarchiveError];
        NSAssert(unarchiveError == nil, @"Error unarchiving NSArray of NSData");

        return result;
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

        // this can't switch to the non-deprecated NSSecureCoding method because the types aren't known ahead of time
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [NSKeyedUnarchiver unarchiveObjectWithData:objectData];
        #pragma clang diagnostic pop
    }
    
    return nil;
}

#pragma mark - Other Commands

- (BOOL)setUserInterfaceAnimationsEnabled:(BOOL)enabled
{
    _userInterfaceAnimationsEnabled = enabled;
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: [@(enabled) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandSetUserInterfaceAnimations params:params] boolValue];
}

- (BOOL)userInterfaceAnimationsEnabled
{
    return _userInterfaceAnimationsEnabled;
}

- (BOOL)setUserInterfaceAnimationSpeed:(NSInteger)speed
{
    _userInterfaceAnimationSpeed = speed;
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: [@(speed) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandSetUserInterfaceAnimationSpeed params:params] boolValue];
}

- (NSInteger)userInterfaceAnimationSpeed
{
    return _userInterfaceAnimationSpeed;
}

#pragma mark - XCUITest scroll extensions

- (BOOL)scrollTableViewWithIdentifier:(NSString *)identifier toRowIndex:(NSInteger)row animated:(BOOL)flag
{
    NSAssert([identifier length] > 0, @"Invalid empty identifier!");
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: identifier,
                                                     SBTUITunnelObjectValueKey: [@(row) stringValue],
                                                     SBTUITunnelObjectAnimatedKey: [@(flag) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandXCUIExtensionScrollTableView params:params] boolValue];
}

- (BOOL)scrollTableViewWithIdentifier:(NSString *)identifier toElementWithIdentifier:(NSString *)targetIdentifier animated:(BOOL)flag
{
    NSAssert([identifier length] > 0, @"Invalid empty identifier!");
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: identifier,
                                                     SBTUITunnelObjectValueKey: targetIdentifier,
                                                     SBTUITunnelXCUIExtensionScrollType: @"identifier",
                                                     SBTUITunnelObjectAnimatedKey: [@(flag) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandXCUIExtensionScrollTableView params:params] boolValue];
}

- (BOOL)scrollCollectionViewWithIdentifier:(NSString *)identifier toElementIndex:(NSInteger)row animated:(BOOL)flag
{
    NSAssert([identifier length] > 0, @"Invalid empty identifier!");
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: identifier,
                                                     SBTUITunnelObjectValueKey: [@(row) stringValue],
                                                     SBTUITunnelObjectAnimatedKey: [@(flag) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandXCUIExtensionScrollCollectionView params:params] boolValue];
}

- (BOOL)scrollCollectionViewWithIdentifier:(NSString *)identifier toElementWithIdentifier:(NSString *)targetIdentifier animated:(BOOL)flag {
    NSAssert([identifier length] > 0, @"Invalid empty identifier!");
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: identifier,
                                                     SBTUITunnelObjectValueKey: targetIdentifier,
                                                     SBTUITunnelXCUIExtensionScrollType: @"identifier",
                                                     SBTUITunnelObjectAnimatedKey: [@(flag) stringValue]};

    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandXCUIExtensionScrollCollectionView params:params] boolValue];
}

- (BOOL)scrollScrollViewWithIdentifier:(NSString *)identifier toElementWithIdentifier:(NSString *)targetIdentifier animated:(BOOL)flag
{
    NSAssert([identifier length] > 0, @"Invalid empty identifier!");
    NSAssert([targetIdentifier length] > 0, @"Invalid empty target identifier!");
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: identifier,
                                                     SBTUITunnelObjectValueKey: targetIdentifier,
                                                     SBTUITunnelXCUIExtensionScrollType: @"identifier",
                                                     SBTUITunnelObjectAnimatedKey: [@(flag) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandXCUIExtensionScrollScrollView params:params] boolValue];
}


- (BOOL)scrollScrollViewWithIdentifier:(NSString *)identifier toOffset:(CGFloat)targetOffset animated:(BOOL)flag
{
    NSAssert([identifier length] > 0, @"Invalid empty identifier!");
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: identifier,
                                                     SBTUITunnelObjectValueKey: [@(targetOffset) stringValue],
                                                     SBTUITunnelXCUIExtensionScrollType: @"offset",
                                                     SBTUITunnelObjectAnimatedKey: [@(flag) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandXCUIExtensionScrollScrollView params:params] boolValue];
}

#pragma mark - XCUITest 3D touch extensions

- (BOOL)forcePressViewWithIdentifier:(NSString *)identifier
{
    NSAssert([identifier length] > 0, @"Invalid empty identifier!");
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: identifier};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandXCUIExtensionForceTouchView params:params] boolValue];
}

#pragma mark - XCUITest CLLocation extensions

- (BOOL)coreLocationStubEnabled:(BOOL)flag
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectValueKey: flag ? @"YES" : @"NO"};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCoreLocationStubbing params:params] boolValue];
}

- (BOOL)coreLocationStubAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectValueKey: [@(status) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCoreLocationStubAuthorizationStatus params:params] boolValue];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
- (BOOL)coreLocationStubAccuracyAuthorization:(CLAccuracyAuthorization)authorization API_AVAILABLE(ios(14))
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectValueKey: [@(authorization) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCoreLocationStubAccuracyAuthorization params:params] boolValue];
}
#endif

- (BOOL)coreLocationStubLocationServicesEnabled:(BOOL)flag
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectValueKey: flag ? @"YES" : @"NO"};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCoreLocationStubServiceStatus params:params] boolValue];
}

- (BOOL)coreLocationNotifyLocationUpdate:(NSArray<CLLocation *>*)locations
{
    NSAssert([locations count] > 0, @"Location array should contain at least one element!");
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: [self base64SerializeObject:locations]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCoreLocationNotifyUpdate params:params] boolValue];
}

- (BOOL)coreLocationStubManagerLocation:(CLLocation *)location
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: [self base64SerializeObject:@[location ?: [NSNull null]]]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCoreLocationStubManagerLocation params:params] boolValue];
}

- (BOOL)coreLocationNotifyLocationError:(NSError *)error
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: [self base64SerializeObject:error]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandCoreLocationNotifyFailure params:params] boolValue];
}

#pragma mark - XCUITest UNUserNotificationCenter extensions

- (BOOL)notificationCenterStubEnabled:(BOOL)flag API_AVAILABLE(ios(10))
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectValueKey: flag ? @"YES" : @"NO"};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNotificationCenterStubbing params:params] boolValue];
}

- (BOOL)notificationCenterStubAuthorizationStatus:(UNAuthorizationStatus)status API_AVAILABLE(ios(10))
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectValueKey: [@(status) stringValue]};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandNotificationCenterStubAuthorizationStatus params:params] boolValue];
}

#pragma mark - XCUITest WKWebView stubbing

- (BOOL)wkWebViewStubEnabled:(BOOL)flag
{
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectValueKey: flag ? @"YES" : @"NO"};
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandWKWebViewStubbing params:params] boolValue];
}

#pragma mark - WebSocket

- (NSInteger)launchWebSocketWithIdentifier:(NSString *)identifier
{
    NSAssert([identifier length] > 0, @"Invalid empty identifier!");
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: identifier};
    
    NSString *portString = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandLaunchWebSocket params:params];
    
    return [portString integerValue];
}

- (BOOL)stubWebSocketReceiveMessage:(NSData *)responseData withIdentifier:(NSString *)identifier
{
    NSAssert([identifier length] > 0, @"Invalid empty identifier!");
    NSAssert(responseData != nil, @"Response data cannot be nil!");
    

    NSString *responseDataBase64 = [self base64SerializeData:responseData];
    NSDictionary<NSString *, NSString *> *params = @{
        SBTUITunnelObjectKey: identifier,
        SBTUITunnelStubResponseKey: responseDataBase64
    };
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandStubWebSocket params:params] boolValue];
}

- (NSArray<NSData *> *)flushWebSocketMessagesWithIdentifier:(NSString *)identifier
{
    NSAssert([identifier length] > 0, @"Invalid empty identifier!");
    
    NSDictionary<NSString *, NSString *> *params = @{SBTUITunnelObjectKey: identifier};
    
    NSString *base64String = [self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandFlushWebSocketMessages params:params];
    
    if (base64String.length > 0) {
        NSData *archivedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
        if (archivedData) {
            NSError *unarchiveError = nil;
            NSSet *classes = [NSSet setWithObjects:[NSArray class], [NSData class], nil];
            NSArray<NSData *> *messages = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:archivedData error:&unarchiveError];
            
            if (!unarchiveError && messages) {
                return messages;
            } else {
                NSLog(@"[SBTUITestTunnel] Error unarchiving WebSocket messages: %@", unarchiveError);
            }
        }
    }
    
    return @[];
}

- (BOOL)sendWebSocketMessage:(NSData *)message withIdentifier:(NSString *)identifier
{
    NSAssert([identifier length] > 0, @"Invalid empty identifier!");
    NSAssert(message != nil, @"Message data cannot be nil!");
    
    NSString *messageBase64 = [self base64SerializeData:message];
    NSDictionary<NSString *, NSString *> *params = @{
        SBTUITunnelObjectKey: identifier,
        SBTUITunnelObjectValueKey: messageBase64
    };
    
    return [[self sendSynchronousRequestWithPath:SBTUITunneledApplicationCommandSendWebSocketMessage params:params] boolValue];
}


#pragma mark - Helper Methods

- (NSString *)base64SerializeObject:(id)obj
{
    NSData *objData = [NSKeyedArchiver archivedDataWithRootObject:obj requiringSecureCoding:NO error:nil];
    return [self base64SerializeData:objData];
}

- (NSString *)base64SerializeData:(NSData *)data
{
    if (!data) {
        [self shutDownWithErrorMessage:@"[SBTUITestTunnel] Failed to serialize object" code:SBTUITestTunnelErrorOtherFailure];
        return @"";
    } else {
        if (self.ipcConnection) {
            return [data base64EncodedStringWithOptions:0];
        } else {
            return [[data base64EncodedStringWithOptions:0] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
        }
    }
}

- (NSString *)sendSynchronousRequestWithPath:(NSString *)path params:(NSDictionary<NSString *, NSString *> *)params assertOnError:(BOOL)assertOnError
{
    if (self.ipcConnection) {
        if (!self.connected) {
            return @"";
        }

        // https://github.com/wix/DetoxIPC/blob/637eb3abca0e2ec3c9f86202cdab839532a1b90b/DetoxIPC/DTXIPCConnection.h#L70
        if (![NSThread isMainThread]) {
            __block NSString *ret;
            __weak typeof(self)weakSelf = self;
            
            __block BOOL lockedDone = NO;
            
            NSLock *lock = [[NSLock alloc] init];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                ret = [weakSelf sendSynchronousRequestWithPath:path params:params assertOnError:assertOnError];
                
                [lock lock];
                lockedDone = YES;
                [lock unlock];
            });
            
            NSTimeInterval start = CFAbsoluteTimeGetCurrent();
            BOOL done = NO;
            while (!done && CFAbsoluteTimeGetCurrent() - start < SBTUITunneledApplicationDefaultTimeout) {
                [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
                
                [lock lock];
                done = lockedDone;
                [lock unlock];
            }

            return ret;
        }

        NSMutableDictionary *ipcParams = [(params ?: @{}) mutableCopy];
        ipcParams[SBTUITunnelIPCCommand] = path;
                
        __block NSDictionary *ret = nil;
        [self.ipcProxy performCommandWithParameters:ipcParams block:^void(NSDictionary *dict) {
            ret = dict;
        }];

        return ret[SBTUITunnelResponseResultKey];
    } else if (self.connectionlessBlock) {
        if ([NSThread isMainThread]) {
            return self.connectionlessBlock(path, params);
        } else {
            __block NSString *ret = @"";
            __weak typeof(self)weakSelf = self;
            dispatch_sync(dispatch_get_main_queue(), ^{
                ret = weakSelf.connectionlessBlock(path, params);
            });
            return ret;
        }
    } else if (self.connectionPort == 0) {
        return nil; // connection still not established
    }
    
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%d/%@", SBTUITunneledApplicationDefaultHost, (unsigned int)self.connectionPort, path];
    
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
        NSError *error = [self.class errorWithCode:SBTUITestTunnelErrorOtherFailure
                                           message:@"[SBTUITestTunnel] Did fail to create url component"];
        [self shutDownWithError:error];
        return nil;
    }
    
    dispatch_semaphore_t synchRequestSemaphore = dispatch_semaphore_create(0);
    
    NSURLSession *session = [NSURLSession sharedSession];
    __block NSString *responseId = nil;
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error.code == -1022) {
            NSAssert(NO, @"Check that ATS security policy is properly setup, refer to documentation");
        }
        
        if (![response isKindOfClass:[NSHTTPURLResponse class]] || data == nil) {
            if (assertOnError) {
                NSLog(@"[SBTUITestTunnel] Failed to get http response: %@", request);
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
    
    if (dispatch_semaphore_wait(synchRequestSemaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SBTUITunneledApplicationDefaultTimeout * NSEC_PER_SEC))) != 0) {}
    
    return responseId;
}

- (NSString *)sendSynchronousRequestWithPath:(NSString *)path params:(NSDictionary<NSString *, NSString *> *)params
{
    return [self sendSynchronousRequestWithPath:path params:params assertOnError:YES];
}

#pragma mark - Error Helpers

+ (NSError *)errorWithCode:(SBTUITestTunnelError)code message:(NSString *)message
{
    return [NSError errorWithDomain:kSBTUITestTunnelErrorDomain
                               code:code
                           userInfo:@{ NSLocalizedDescriptionKey : message }];
}

@end
