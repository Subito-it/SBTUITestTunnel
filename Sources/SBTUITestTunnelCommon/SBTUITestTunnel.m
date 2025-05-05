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

#import "include/SBTUITestTunnel.h"

NSString * const SBTUITunneledApplicationLaunchEnvironmentIPCKey = @"SBTUITunneledApplicationLaunchEnvironmentIPCKey";
NSString * const SBTUITunneledApplicationLaunchEnvironmentPortKey = @"SBTUITunneledApplicationLaunchEnvironmentPortKey";
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

NSString * const SBTUITunnelIPCCommand = @"ipc_command";

NSString * const SBTUITunnelHTTPMethod = @"POST";

NSString * const SBTUITunnelStubMatchRuleKey = @"match_rule";
NSString * const SBTUITunnelStubResponseKey = @"response";

NSString * const SBTUITunnelRewriteMatchRuleKey = @"match_rule";
NSString * const SBTUITunnelRewriteKey = @"rewrite_rule";

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

NSString * const SBTUITunnelXCUIExtensionScrollType = @"type";

NSString * const SBTUITunnelCustomCommandKey = @"cust_command";

NSString * const SBTUITunneledApplicationCommandPing = @"commandPing";
NSString * const SBTUITunneledApplicationCommandQuit = @"commandQuit";

NSString * const SBTUITunneledApplicationCommandStubMatching = @"commandStubMatching";
NSString * const SBTUITunneledApplicationCommandStubRequestsRemove = @"commandStubRequestsRemove";
NSString * const SBTUITunneledApplicationCommandStubRequestsRemoveAll = @"commandStubRequestsRemoveAll";
NSString * const SBTUITunneledApplicationCommandStubRequestsAll = @"commandStubRequestsAll";

NSString * const SBTUITunneledApplicationCommandRewriteMatching = @"commandRewriteMatching";
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

NSString * const SBTUITunneledApplicationCommandCookieBlockMatching = @"commandCookiesBlockMatching";
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

NSString * const SBTUITunneledApplicationCommandStartupCommandsCompleted = @"commandStartupCompleted";

NSString * const SBTUITunneledApplicationCommandXCUIExtensionScrollTableView = @"commandScrollTableView";
NSString * const SBTUITunneledApplicationCommandXCUIExtensionScrollCollectionView = @"commandScrollCollectionView";
NSString * const SBTUITunneledApplicationCommandXCUIExtensionScrollScrollView = @"commandScrollScrollView";
NSString * const SBTUITunneledApplicationCommandXCUIExtensionForceTouchView = @"commandForceTouchPopView";
NSString * const SBTUITunneledApplicationCommandCoreLocationStubbing = @"commandCoreLocationStubbing";
NSString * const SBTUITunneledApplicationCommandCoreLocationStubManagerLocation = @"commandCoreLocationStubManagerLocation";
NSString * const SBTUITunneledApplicationCommandCoreLocationStubAuthorizationStatus = @"commandCoreLocationStubAuthorizationStatus";
NSString * const SBTUITunneledApplicationCommandCoreLocationStubAccuracyAuthorization = @"commandCoreLocationStubAccuracyAuthorization";
NSString * const SBTUITunneledApplicationCommandCoreLocationStubServiceStatus = @"commandCoreLocationStubServiceStatus";
NSString * const SBTUITunneledApplicationCommandCoreLocationNotifyUpdate = @"commandCoreLocationNotifyUpdate";
NSString * const SBTUITunneledApplicationCommandCoreLocationNotifyFailure = @"commandCoreLocationNotifyFailure";
NSString * const SBTUITunneledApplicationCommandNotificationCenterStubbing = @"commandNotificationCenterStubbing";
NSString * const SBTUITunneledApplicationCommandNotificationCenterStubAuthorizationStatus = @"commandNotificationCenterStubAuthorizationStatus";
NSString * const SBTUITunneledApplicationCommandWKWebViewStubbing = @"commandWkWebViewStubbing"; 

NSString * const SBTUITunneledApplicationCommandLaunchWebSocket = @"commandLaunchWebSocket";

NSString * const SBTUITunneledNSURLProtocolHTTPBodyKey = @"SBTUITunneledNSURLProtocolHTTPBodyKey";

@implementation SBTUITunnelStartupCommand

- (instancetype)initWithCoder:(NSCoder *)decoder
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
