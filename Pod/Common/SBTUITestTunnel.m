// SBTUITestTunnel.m
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

#import "SBTUITestTunnel.h"

const uint16_t SBTUITunneledApplicationDefaultPort = 8666;
NSString *  const SBTUITunneledApplicationDefaultHost = @"localhost";

const double SBTUITunnelStubsDownloadSpeedGPRS   =-    56 / 8; // kbps -> KB/s
const double SBTUITunnelStubsDownloadSpeedEDGE   =-   128 / 8; // kbps -> KB/s
const double SBTUITunnelStubsDownloadSpeed3G     =-  3200 / 8; // kbps -> KB/s
const double SBTUITunnelStubsDownloadSpeed3GPlus =-  7200 / 8; // kbps -> KB/s
const double SBTUITunnelStubsDownloadSpeedWifi   =- 12000 / 8; // kbps -> KB/s

NSString * const SBTUITunneledApplicationLaunchSignal = @"SBTUITunneledApplicationLaunchSignal";
NSString * const SBTUITunneledApplicationLaunchOptionResetFilesystem = @"SBTUITunneledApplicationLaunchOptionResetFilesystem";
NSString * const SBTUITunneledApplicationLaunchOptionDisableUITextFieldAutocomplete = @"SBTUITunneledApplicationLaunchOptionDisableUITextFieldAutocomplete";
NSString * const SBTUITunneledApplicationLaunchOptionHasStartupCommands = @"SBTUITunneledApplicationLaunchOptionHasStartupCommands";

NSString * const SBTUITunnelHTTPMethod = @"POST";

NSString * const SBTUITunnelStubQueryRuleKey = @"rule";
NSString * const SBTUITunnelStubQueryReturnDataKey = @"ret_data";
NSString * const SBTUITunnelStubQueryReturnCodeKey = @"ret_code";
NSString * const SBTUITunnelStubQueryIterations = @"iterations";
NSString * const SBTUITunnelStubQueryResponseTimeKey = @"time_response";
NSString * const SBTUITunnelStubQueryMimeTypeKey = @"mime_type";

NSString * const SBTUITunnelProxyQueryRuleKey = @"rule";
NSString * const SBTUITunnelProxyQueryResponseTimeKey = @"time_response";

NSString * const SBTUITunnelObjectKey = @"obj";
NSString * const SBTUITunnelObjectKeyKey = @"key";

NSString * const SBTUITunnelUploadDataKey = @"data";
NSString * const SBTUITunnelUploadDestPathKey = @"dest";
NSString * const SBTUITunnelUploadBasePathKey = @"base";

NSString * const SBTUITunnelDownloadPathKey = @"path";
NSString * const SBTUITunnelDownloadBasePathKey = @"base";

NSString * const SBTUITunnelResponseResultKey = @"result";

NSString * const SBTUITunnelCustomCommandKey = @"cust_command";

NSString * const SBTUITunneledApplicationCommandPing = @"commandPing";
NSString * const SBTUITunneledApplicationCommandQuit = @"commandQuit";

NSString * const SBTUITunneledApplicationCommandCruising = @"commandCruising";

NSString * const SBTUITunneledApplicationCommandStubPathMatching = @"commandStubPathMatching";
NSString * const SBTUITunneledApplicationcommandStubAndRemovePathMatching = @"commandStubAndRemovePathMatching";
NSString * const SBTUITunneledApplicationCommandstubRequestsRemove = @"commandStubRequestsRemove";
NSString * const SBTUITunneledApplicationcommandStubRequestsRemoveAll = @"commandStubRequestsRemoveAll";

NSString * const SBTUITunneledApplicationCommandMonitorPathMatching = @"commandMonitorPathMatching";
NSString * const SBTUITunneledApplicationCommandMonitorRemove = @"commandMonitorRemove";
NSString * const SBTUITunneledApplicationcommandMonitorRemoveAll = @"commandMonitorsRemoveAll";
NSString * const SBTUITunneledApplicationcommandMonitorPeek = @"commandMonitorPeek";
NSString * const SBTUITunneledApplicationcommandMonitorFlush = @"commandMonitorFlush";

NSString * const SBTUITunneledApplicationCommandThrottlePathMatching = @"commandThrottlePathMatching";
NSString * const SBTUITunneledApplicationCommandThrottleRemove = @"commandThrottleRemove";
NSString * const SBTUITunneledApplicationcommandThrottleRemoveAll = @"commandThrottlesRemoveAll";

NSString * const SBTUITunneledApplicationCommandNSUserDefaultsSetObject = @"commandNSUserDefaultsSetObject";
NSString * const SBTUITunneledApplicationCommandNSUserDefaultsRemoveObject = @"commandNSUserDefaultsRemoveObject";
NSString * const SBTUITunneledApplicationCommandNSUserDefaultsObject = @"commandNSUserDefaultsObject";
NSString * const SBTUITunneledApplicationCommandNSUserDefaultsReset = @"commandNSUserDefaultsReset";

NSString * const SBTUITunneledApplicationCommandKeychainSetObject = @"commandKeychainSetObject";
NSString * const SBTUITunneledApplicationCommandKeychainRemoveObject = @"commandKeychainRemoveObject";
NSString * const SBTUITunneledApplicationCommandKeychainObject = @"commandKeychainObject";
NSString * const SBTUITunneledApplicationCommandKeychainReset = @"commandKeychainReset";

NSString * const SBTUITunneledApplicationCommandMainBundleInfoDictionary = @"commandMainBundleInfoDictionary";

NSString * const SBTUITunneledApplicationCommandCustom = @"commandCustom";

NSString * const SBTUITunneledApplicationCommandSetUserInterfaceAnimations = @"commandSetUIAnimations";
NSString * const SBTUITunneledApplicationCommandSetUserInterfaceAnimationSpeed = @"commandSetUIAnimationSpeed";

NSString * const SBTUITunneledApplicationCommandUploadData = @"commandUpload";
NSString * const SBTUITunneledApplicationCommandDownloadData = @"commandDownload";

NSString * const SBTUITunneledApplicationCommandShutDown = @"commandShutDown";

NSString * const SBTUITunneledApplicationCommandStartupCommandsCompleted = @"commandStartupCompleted";

NSString * const SBTUITunneledNSURLProtocolHTTPBodyKey = @"SBTUITunneledNSURLProtocolHTTPBodyKey";

@implementation SBTUITunnelStartupCommand

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.path = [decoder decodeObjectForKey:@"path"];
        self.headers = [decoder decodeObjectForKey:@"headers"];
        self.query = [decoder decodeObjectForKey:@"query"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.path forKey:@"path"];
    [encoder encodeObject:self.headers forKey:@"headers"];
    [encoder encodeObject:self.query forKey:@"query"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"path: %@\nheaders: %@\nquery: %@\n", self.path, self.headers, self.query];
}

@end

@implementation SBTMonitoredNetworkRequest : NSObject

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.timestamp = [[decoder decodeObjectForKey:@"timestamp"] doubleValue];
        self.requestTime = [[decoder decodeObjectForKey:@"requestTime"] doubleValue];
        self.request = [decoder decodeObjectForKey:@"request"];
        self.originalRequest = [decoder decodeObjectForKey:@"originalRequest"];
        self.response = [decoder decodeObjectForKey:@"response"];
        self.responseData = [decoder decodeObjectForKey:@"responseData"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:@(self.timestamp) forKey:@"timestamp"];
    [encoder encodeObject:@(self.requestTime) forKey:@"requestTime"];
    [encoder encodeObject:self.request forKey:@"request"];
    [encoder encodeObject:self.originalRequest forKey:@"originalRequest"];
    [encoder encodeObject:self.response forKey:@"response"];
    [encoder encodeObject:self.responseData forKey:@"responseData"];
}

- (NSString *)responseString
{
    NSString *ret = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    
    if (!ret) {
        ret = [[NSString alloc] initWithData:self.responseData encoding:NSASCIIStringEncoding];
    }
    
    return ret;
}

- (id)responseJSON
{
    NSError *error = nil;
    NSDictionary *ret = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableContainers error:&error];
    
    return (ret && !error) ? ret : nil;
}

@end

@interface SBTRequestMatch()

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *query;
@property (nonatomic, strong) NSString *method;

@end

@implementation SBTRequestMatch : NSObject

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init]) {
        self.url = [decoder decodeObjectForKey:@"url"];
        self.query = [decoder decodeObjectForKey:@"query"];
        self.method = [decoder decodeObjectForKey:@"method"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.url forKey:@"url"];
    [encoder encodeObject:self.query forKey:@"query"];
    [encoder encodeObject:self.method forKey:@"method"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"URL: %@\nQuery: %@\nMethod: %@", self.url ?: @"N/A", self.query ?: @"N/A", self.method ?: @"N/A"];
}

+ (instancetype)URL:(NSString *)url
{
    SBTRequestMatch *ret = [[SBTRequestMatch alloc] init];
    ret.url = url;
    
    return ret;
}

+ (instancetype)URL:(NSString *)url query:(NSString *)query
{
    SBTRequestMatch *ret = [self URL:url];
    ret.query = query;
    
    return ret;
}

+ (instancetype)URL:(NSString *)url query:(NSString *)query method:(NSString *)method
{
    SBTRequestMatch *ret = [self URL:url query:query];
    ret.method = method;
    
    return ret;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"

+ (instancetype)URL:(NSString *)url method:(NSString *)method
{
    return [self URL:url query:nil method:method];
}

+ (instancetype)query:(NSString *)query
{
    return [self URL:nil query:query method:nil];
}

+ (instancetype)query:(NSString *)query method:(NSString *)method
{
    return [self URL:nil query:query method:method];
}

+ (instancetype)method:(NSString *)method
{
    return [self URL:nil query:nil method:method];
}

#pragma clang diagnostic pop

@end

#endif
