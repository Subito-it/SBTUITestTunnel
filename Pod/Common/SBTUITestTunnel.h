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

#if DEBUG

#import <Foundation/Foundation.h>

extern const double
SBTUITunnelStubsDownloadSpeedGPRS,
SBTUITunnelStubsDownloadSpeedEDGE,
SBTUITunnelStubsDownloadSpeed3G,
SBTUITunneltubsDownloadSpeed3GPlus,
SBTUITunnelStubsDownloadSpeedWifi;

extern NSString * _Nonnull const SBTUITunneledApplicationLaunchOptionResetFilesystem;
extern NSString * _Nonnull const SBTUITunneledApplicationLaunchOptionDisableUITextFieldAutocomplete;
extern NSString * _Nonnull const SBTUITunneledApplicationLaunchEnvironmentBonjourNameKey;
extern NSString * _Nonnull const SBTUITunneledApplicationLaunchEnvironmentRemotePortKey;
extern NSString * _Nonnull const SBTUITunneledApplicationLaunchOptionHasStartupCommands;

extern NSString * _Nonnull const SBTUITunnelHTTPMethod;

extern NSString * _Nonnull const SBTUITunnelStubQueryRuleKey;
extern NSString * _Nonnull const SBTUITunnelStubQueryReturnDataKey;
extern NSString * _Nonnull const SBTUITunnelStubQueryReturnCodeKey;
extern NSString * _Nonnull const SBTUITunnelStubQueryIterations;
extern NSString * _Nonnull const SBTUITunnelStubQueryResponseTimeKey;
extern NSString * _Nonnull const SBTUITunnelStubQueryMimeTypeKey;

extern NSString * _Nonnull const SBTUITunnelProxyQueryRuleKey;
extern NSString * _Nonnull const SBTUITunnelProxyQueryResponseTimeKey;

extern NSString * _Nonnull const SBTUITunnelObjectKey;
extern NSString * _Nonnull const SBTUITunnelObjectKeyKey;

extern NSString * _Nonnull const SBTUITunnelUploadDataKey;
extern NSString * _Nonnull const SBTUITunnelUploadDestPathKey;
extern NSString * _Nonnull const SBTUITunnelUploadBasePathKey;

extern NSString * _Nonnull const SBTUITunnelDownloadPathKey;
extern NSString * _Nonnull const SBTUITunnelDownloadBasePathKey;

extern NSString * _Nonnull const SBTUITunnelResponseResultKey;

extern NSString * _Nonnull const SBTUITunnelCustomCommandKey;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandStubPathThatMatchesRegex;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandStubPathThatContainsQueryParams;
extern NSString * _Nonnull const SBTUITunneledApplicationcommandStubAndRemovePathThatMatchesRegex;
extern NSString * _Nonnull const SBTUITunneledApplicationcommandStubAndRemovePathThatContainsQueryParams;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandstubRequestsRemove;
extern NSString * _Nonnull const SBTUITunneledApplicationcommandStubRequestsRemoveAll;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandMonitorPathThatMatchesRegex;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandMonitorPathThatContainsQueryParams;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandMonitorRemove;
extern NSString * _Nonnull const SBTUITunneledApplicationcommandMonitorRemoveAll;
extern NSString * _Nonnull const SBTUITunneledApplicationcommandMonitorPeek;
extern NSString * _Nonnull const SBTUITunneledApplicationcommandMonitorFlush;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandThrottlePathThatMatchesRegex;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandThrottlePathThatContainsQueryParams;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandThrottleRemove;
extern NSString * _Nonnull const SBTUITunneledApplicationcommandThrottleRemoveAll;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandNSUserDefaultsSetObject;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandNSUserDefaultsRemoveObject;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandNSUserDefaultsObject;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandNSUserDefaultsReset;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandKeychainSetObject;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandKeychainObject;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandKeychainRemoveObject;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandKeychainReset;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandCustom;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandSetUserInterfaceAnimations;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandUploadData;
extern NSString * _Nonnull const SBTUITunneledApplicationCommandDownloadData;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandShutDown;

extern NSString * _Nonnull const SBTUITunneledApplicationCommandStartupCommandsCompleted;

extern NSString * _Nonnull const SBTUITunneledNSURLProtocolHTTPBodyKey;

#pragma mark - Classes

@interface SBTUITunnelStartupCommand: NSObject<NSCoding>

@property (nullable, nonatomic, strong) NSString *path;
@property (nullable, nonatomic, strong) NSDictionary *headers;
@property (nullable, nonatomic, strong) NSDictionary *query;

@end

@interface SBTMonitoredNetworkRequest : NSObject

- (nullable NSString *)responseString;
- (nullable id)responseJSON;

@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) NSTimeInterval requestTime;

@property (nullable, nonatomic, strong) NSURLRequest *request;
@property (nullable, nonatomic, strong) NSURLRequest *originalRequest;
@property (nullable, nonatomic, strong) NSHTTPURLResponse *response;

@property (nullable, nonatomic, strong) NSData *responseData;

@end

#endif
