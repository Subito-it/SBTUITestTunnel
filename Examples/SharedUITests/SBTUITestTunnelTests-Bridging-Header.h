// The shared KeepAlive tests exercise the bundled HTTP server directly.
// Import its headers only in the SPM test targets, without making the server's
// implementation details part of SBTUITestTunnelServer's public interface.
#import "../../Sources/SBTUITestTunnelServer/GCDWebServer/Core/SBTWebServer.h"
#import "../../Sources/SBTUITestTunnelServer/GCDWebServer/Responses/SBTWebServerDataResponse.h"
