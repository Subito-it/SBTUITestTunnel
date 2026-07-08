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
                UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: nil)
            }
            return nil
        }
    }
}
