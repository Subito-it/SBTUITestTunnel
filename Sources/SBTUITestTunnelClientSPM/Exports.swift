// The tunnel is made of 4 packages
// - SBTUITestTunnelSever       Objective-C
// - SBTUITestTunnelClient      Objective-C
// - SBTUITestTunnelCommon      Objective-C
// - SBTUITestTunnelCommonSwift Swift
//
// Swift packages cannot be imported in Objective-C's umbrella headers (which is a problem for SBTUITestTunnelCommonSwift) so we create a separate module which re-exports all required modules.
// To achieve this we need to additionally rename the existing SBTUITestTunnelClient to SBTUITestTunnelClientCocoaPods so that this one can take its place.

@_exported import SBTUITestTunnelClientCocoaPods;
@_exported import SBTUITestTunnelCommonSwift;
@_exported import SBTUITestTunnelCommon;
