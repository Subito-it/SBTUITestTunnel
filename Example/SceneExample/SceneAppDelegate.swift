// SceneAppDelegate.swift
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

import SBTUITestTunnelServer
import UIKit

/// UIScene-based app delegate that mirrors how a modern host app is structured:
/// all process-level launch work (the part that reads tunnel-injected state such
/// as feature toggles / keychain) runs in `didFinishLaunching`, while the window
/// is owned by the scene.
///
/// A launch argument decides where `takeOff()` runs so a single binary can
/// reproduce both integration strategies:
///   * `TAKEOFF_IN_SCENE`      – PR #258 recommendation (broken for this shape).
///   * `TAKEOFF_IN_APPDELEGATE` – restore init before the state is consumed.
@objc(SceneAppDelegate)
final class SceneAppDelegate: UIResponder, UIApplicationDelegate {
    static let takeOffInAppDelegateArg = "TAKEOFF_IN_APPDELEGATE"
    static let takeOffInSceneArg = "TAKEOFF_IN_SCENE"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        LaunchProbe.record("didFinishLaunching:start")

        registerProbeCommand()

        if ProcessInfo.processInfo.arguments.contains(Self.takeOffInAppDelegateArg) {
            LaunchProbe.record("takeOff:appDelegate:start")
            let didTakeOff = SBTUITestTunnelServer.takeOff()
            LaunchProbe.record("takeOff:appDelegate:end didTakeOff=\(didTakeOff)")
        }

        // The state consumer: exactly like reading a toggle during launch.
        let seen = LaunchProbe.readInjectedValue()
        LaunchProbe.valueSeenAtDidFinishLaunching = seen
        LaunchProbe.record("didFinishLaunching:end seen=\(seen)")

        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    private func registerProbeCommand() {
        SBTUITestTunnelServer.registerCustomCommandNamed("launchProbe") { _ in
            [
                "events": LaunchProbe.events,
                "seenAtDidFinishLaunching": LaunchProbe.valueSeenAtDidFinishLaunching ?? "nil",
                "seenAtSceneConnection": LaunchProbe.valueSeenAtSceneConnection ?? "nil",
                "valuesSeenAtSceneConnections": LaunchProbe.valuesSeenAtSceneConnections,
            ] as NSDictionary
        }

        // Requests activation of an additional scene so the test can exercise the
        // multi-window path: a scene that connects long after `takeOff()` has
        // returned must still observe the injected state.
        SBTUITestTunnelServer.registerCustomCommandNamed("activateSecondScene") { _ in
            DispatchQueue.main.async {
                UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: nil) { error in
                    // The Simulator's FrontBoard declines this ("declined to
                    // create a scene"); log it so a timeout in the test maps back
                    // to the real reason instead of looking like a slow connection.
                    LaunchProbe.record("activateSecondScene:error=\(error.localizedDescription)")
                }
            }
            return nil
        }

        // Regression command for the scene+IPC deadlock: performs a *synchronous*
        // network request (blocking the calling command queue) whose response is
        // served by the tunnel's own stub proxy. This mirrors a real host app that
        // seeds an authenticated session during its startup block. If the proxy
        // delivered the stubbed response on the main queue, this would deadlock
        // because `takeOff` parks the main thread on the startup semaphore.
        SBTUITestTunnelServer.registerCustomCommandNamed("performSyncStubbedRequest") { obj in
            guard let urlString = obj as? String, let url = URL(string: urlString) else { return "no-url" as NSString }

            let semaphore = DispatchSemaphore(value: 0)
            var result = "timeout"
            // URLSession.shared honours the globally-registered SBTProxyURLProtocol
            // (a custom-configuration session would not), so the stub intercepts it.
            let task = URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data, let body = String(data: data, encoding: .utf8) {
                    result = body
                }
                semaphore.signal()
            }
            task.resume()

            _ = semaphore.wait(timeout: .now() + 30)
            return result as NSString
        }
    }
}
