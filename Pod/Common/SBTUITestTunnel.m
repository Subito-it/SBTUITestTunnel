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
NSString * const SBTUITunnelStubQueryReturnHeadersKey = @"ret_headers";
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
NSString * const SBTUITunnelResponseDebugKey = @"debug";

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
        self.path = [decoder decodeObjectForKey:NSStringFromSelector(@selector(path))];
        self.headers = [decoder decodeObjectForKey:NSStringFromSelector(@selector(headers))];
        self.query = [decoder decodeObjectForKey:NSStringFromSelector(@selector(query))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.path forKey:NSStringFromSelector(@selector(path))];
    [encoder encodeObject:self.headers forKey:NSStringFromSelector(@selector(headers))];
    [encoder encodeObject:self.query forKey:NSStringFromSelector(@selector(query))];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"path: %@\nheaders: %@\nquery: %@\n", self.path, self.headers, self.query];
}

@end

#endif
