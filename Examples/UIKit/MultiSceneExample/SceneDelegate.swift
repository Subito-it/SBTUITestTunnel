// SceneDelegate.swift
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

@objc(SceneDelegate)
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let sceneIndex = LaunchProbe.valuesSeenAtSceneConnections.count
        LaunchProbe.record("scene:willConnectTo:start index=\(sceneIndex)")

        if ProcessInfo.processInfo.arguments.contains(SceneAppDelegate.takeOffInSceneArg) {
            LaunchProbe.record("takeOff:scene:start")
            let didTakeOff = SBTUITestTunnelServer.takeOff()
            LaunchProbe.record("takeOff:scene:end didTakeOff=\(didTakeOff)")
        }

        let seen = LaunchProbe.readInjectedValue()
        LaunchProbe.valuesSeenAtSceneConnections.append(seen)
        if sceneIndex == 0 {
            LaunchProbe.valueSeenAtSceneConnection = seen
        }

        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let viewController = UIViewController()
        viewController.view.backgroundColor = .white
        viewController.view.accessibilityIdentifier = "scene_root_view"
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        self.window = window
        if sceneIndex == 0 {
            LaunchProbe.windowLayerSpeed = window.layer.speed
        }

        LaunchProbe.record("scene:willConnectTo:end index=\(sceneIndex)")
    }
}
