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

NSString * const SBTUITunneledApplicationLaunchEnvironmentBonjourNameKey = @"SBTUITunneledApplicationLaunchEnvironmentBonjourNameKey";
NSString * const SBTUITunneledApplicationDefaultHost = @"localhost";

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

NSString * const SBTUITunnelStubMatchRuleKey = @"match_rule";
NSString * const SBTUITunnelStubResponseKey = @"response";
NSString * const SBTUITunnelStubIterationsKey = @"iterations";

NSString * const SBTUITunnelRewriteMatchRuleKey = @"match_rule";
NSString * const SBTUITunnelRewriteKey = @"rewrite_rule";
NSString * const SBTUITunnelRewriteIterationsKey = @"iterations";

NSString * const SBTUITunnelLocalExecutionKey = @"local_exec";

NSString * const SBTUITunnelProxyQueryRuleKey = @"rule";
NSString * const SBTUITunnelProxyQueryResponseTimeKey = @"time_response";

NSString * const SBTUITunnelCookieBlockMatchRuleKey = @"rule";
NSString * const SBTUITunnelCookieBlockQueryIterationsKey = @"iterations";

NSString * const SBTUITunnelObjectKey = @"obj";
NSString * const SBTUITunnelObjectValueKey = @"obj_value";
NSString * const SBTUITunnelObjectKeyKey = @"key";

NSString * const SBTUITunnelObjectAnimatedKey = @"animated";

NSString * const SBTUITunnelUserDefaultSuiteNameKey = @"suite_name";

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

NSString * const SBTUITunneledApplicationCommandStubMatching = @"commandStubMatching";
NSString * const SBTUITunneledApplicationCommandStubAndRemoveMatching = @"commandStubAndRemoveMatching";
NSString * const SBTUITunneledApplicationCommandStubRequestsRemove = @"commandStubRequestsRemove";
NSString * const SBTUITunneledApplicationCommandStubRequestsRemoveAll = @"commandStubRequestsRemoveAll";

NSString * const SBTUITunneledApplicationCommandRewriteMatching = @"commandRewriteMatching";
NSString * const SBTUITunneledApplicationCommandRewriteAndRemoveMatching = @"commandRewriteAndRemoveMatching";
NSString * const SBTUITunneledApplicationCommandRewriteRequestsRemove = @"commandRewriteRemove";
NSString * const SBTUITunneledApplicationCommandRewriteRequestsRemoveAll = @"commandRewriteRemoveAll";

NSString * const SBTUITunneledApplicationCommandMonitorMatching = @"commandMonitorMatching";
NSString * const SBTUITunneledApplicationCommandMonitorRemove = @"commandMonitorRemove";
NSString * const SBTUITunneledApplicationCommandMonitorRemoveAll = @"commandMonitorsRemoveAll";
NSString * const SBTUITunneledApplicationCommandMonitorPeek = @"commandMonitorPeek";
NSString * const SBTUITunneledApplicationCommandMonitorFlush = @"commandMonitorFlush";

NSString * const SBTUITunneledApplicationCommandThrottleMatching = @"commandThrottleMatching";
NSString * const SBTUITunneledApplicationCommandThrottleRemove = @"commandThrottleRemove";
NSString * const SBTUITunneledApplicationCommandThrottleRemoveAll = @"commandThrottlesRemoveAll";

NSString * const SBTUITunneledApplicationCommandCookieBlockAndRemoveMatching = @"commandCookiesBlockAndRemoveMatching";
NSString * const SBTUITunneledApplicationCommandCookieBlockRemove = @"commandCookiesBlockRemove";
NSString * const SBTUITunneledApplicationCommandCookieBlockRemoveAll = @"commandCookiesBlockRemoveAll";

NSString * const SBTUITunneledApplicationCommandNSUserDefaultsSetObject = @"commandNSUserDefaultsSetObject";
NSString * const SBTUITunneledApplicationCommandNSUserDefaultsRemoveObject = @"commandNSUserDefaultsRemoveObject";
NSString * const SBTUITunneledApplicationCommandNSUserDefaultsObject = @"commandNSUserDefaultsObject";
NSString * const SBTUITunneledApplicationCommandNSUserDefaultsReset = @"commandNSUserDefaultsReset";

NSString * const SBTUITunneledApplicationCommandMainBundleInfoDictionary = @"commandMainBundleInfoDictionary";

NSString * const SBTUITunneledApplicationCommandCustom = @"commandCustom";

NSString * const SBTUITunneledApplicationCommandSetUserInterfaceAnimations = @"commandSetUIAnimations";
NSString * const SBTUITunneledApplicationCommandSetUserInterfaceAnimationSpeed = @"commandSetUIAnimationSpeed";

NSString * const SBTUITunneledApplicationCommandUploadData = @"commandUpload";
NSString * const SBTUITunneledApplicationCommandDownloadData = @"commandDownload";

NSString * const SBTUITunneledApplicationCommandShutDown = @"commandShutDown";

NSString * const SBTUITunneledApplicationCommandStartupCommandsCompleted = @"commandStartupCompleted";

NSString * const SBTUITunneledApplicationCommandXCUIExtensionScrollTableView = @"commandScrollTableView";
NSString * const SBTUITunneledApplicationCommandXCUIExtensionScrollCollectionView = @"commandScrollCollectionView";
NSString * const SBTUITunneledApplicationCommandXCUIExtensionScrollScrollView = @"commandScrollScrollView";
NSString * const SBTUITunneledApplicationCommandXCUIExtensionForceTouchView = @"commandForceTouchPopView";

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
