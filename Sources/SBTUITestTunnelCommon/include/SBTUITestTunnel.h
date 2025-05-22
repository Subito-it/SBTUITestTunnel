// SBTUITestTunnel.h
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

@import Foundation;
@import ObjectiveC.NSObject;

extern NSString * _Nonnull const SBTUITunneledApplicationLaunchEnvironmentIPCKey;
extern NSString * _Nonnull const SBTUITunneledApplicationLaunchEnvironmentPortKey;
extern NSString * _Nonnull const SBTUITunneledApplicationDefaultHost;

extern const double
SBTUITunnelStubsDownloadSpeedGPRS,
SBTUITunnelStubsDownloadSpeedEDGE,
SBTUITunnelStubsDownloadSpeed3G,
SBTUITunneltubsDownloadSpeed3GPlus,
SBTUITunnelStubsDownloadSpeedWifi;

extern NSString * _Nonnull const SBTUITunneledApplicationLaunchSignal;
extern NSString * _Nonnull const SBTUITunneledApplicationLaunchOptionResetFilesystem;
extern NSString * _Nonnull const SBTUITunneledApplicationLaunchOptionDisableKeepAlive;
extern NSString * _Nonnull const SBTUITunneledApplicationLaunchOptionDisableUITextFieldAutocomplete;
extern NSString * _Nonnull const SBTUITunneledApplicationLaunchOptionHasStartupCommands;

extern NSString * _Nonnull const SBTUITunnelIPCCommand;

extern NSString * _Nonnull const SBTUITunnelHTTPMethod;

extern NSString * _Nonnull const SBTUITunnelStubMatchRuleKey;
extern NSString * _Nonnull const SBTUITunnelStubResponseKey;

extern NSString * _Nonnull const SBTUITunnelRewriteMatchRuleKey;
extern NSString * _Nonnull const SBTUITunnelRewriteKey;

extern NSString * _Nonnull const SBTUITunnelProxyQueryRuleKey;
extern NSString * _Nonnull const SBTUITunnelProxyQueryResponseTimeKey;

extern NSString * _Nonnull const SBTUITunnelCookieBlockMatchRuleKey;
extern NSString * _Nonnull const SBTUITunnelCookieBlockQueryIterationsKey;

extern NSString * _Nonnull const SBTUITunnelObjectKey;
extern NSString * _Nonnull const SBTUITunnelObjectValueKey;
extern NSString * _Nonnull const SBTUITunnelObjectKeyKey;

extern NSString * _Nonnull const SBTUITunnelObjectAnimatedKey;

extern NSString * _Nonnull const SBTUITunnelUserDefaultSuiteNameKey;

extern NSString * _Nonnull const SBTUITunnelUploadDataKey;
extern NSString * _Nonnull const SBTUITunnelUploadDestPathKey;
extern NSString * _Nonnull const SBTUITunnelUploadBasePathKey;

extern NSString * _Nonnull const SBTUITunnelDownloadPathKey;
extern NSString * _Nonnull const SBTUITunnelDownloadBasePathKey;

extern NSString * _Nonnull const SBTUITunnelResponseResultKey;
extern NSString * _Nonnull const SBTUITunnelResponseDebugKey;

extern NSString * _Nonnull const SBTUITunnelXCUIExtensionScrollType;

extern NSString * _Nonnull const SBTUITunnelCustomCommandKey;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandPing;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandQuit;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandStubMatching;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandStubRequestsRemove;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandStubRequestsRemoveAll;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandStubRequestsAll;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandRewriteMatching;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandRewriteRequestsRemove;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandRewriteRequestsRemoveAll;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandMonitorMatching;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandMonitorRemove;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandMonitorRemoveAll;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandMonitorPeek;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandMonitorFlush;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandThrottleMatching;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandThrottleRemove;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandThrottleRemoveAll;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandCookieBlockMatching;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandCookieBlockRemove;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandCookieBlockRemoveAll;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandNSUserDefaultsSetObject;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandNSUserDefaultsRemoveObject;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandNSUserDefaultsObject;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandNSUserDefaultsReset;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandNSUserDefaultsRegisterDefaults;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandMainBundleInfoDictionary;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandCustom;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandSetUserInterfaceAnimations;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandSetUserInterfaceAnimationSpeed;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandUploadData;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandDownloadData;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandStartupCommandsCompleted;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandXCUIExtensionScrollTableView;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandXCUIExtensionScrollCollectionView;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandXCUIExtensionScrollScrollView;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandXCUIExtensionForceTouchView;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandCoreLocationStubbing;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandCoreLocationStubManagerLocation;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandCoreLocationStubAuthorizationStatus;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandCoreLocationStubAccuracyAuthorization;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandCoreLocationStubServiceStatus;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandCoreLocationNotifyUpdate;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandCoreLocationNotifyFailure;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandNotificationCenterStubbing;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandNotificationCenterStubAuthorizationStatus;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandWKWebViewStubbing;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandStubWebSocket;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandLaunchWebSocket;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandFlushWebSocketMessages;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandSendWebSocketMessage;

extern NSString * _Nonnull const SBTUITunneledNSURLProtocolHTTPBodyKey;

#pragma mark - Classes

@interface SBTUITunnelStartupCommand: NSObject<NSCoding>

@property (nullable, nonatomic, strong) NSString *path;
@property (nullable, nonatomic, strong) NSDictionary *headers;
@property (nullable, nonatomic, strong) NSDictionary *query;

@end
