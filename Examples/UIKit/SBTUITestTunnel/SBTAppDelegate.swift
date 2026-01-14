// SBTAppDelegate.swift
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

import CoreLocation
import SBTUITestTunnelCommon
import SBTUITestTunnelServer
import UIKit
import UserNotifications

@main
class SBTAppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnNil") { object in
            UserDefaults.standard.set(object, forKey: "custom_command_test")
            UserDefaults.standard.synchronize()
            return nil
        }

        SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturn123") { object in
            UserDefaults.standard.set(object, forKey: "custom_command_test")
            UserDefaults.standard.synchronize()
            return "123" as NSObject
        }

        SBTUITestTunnelServer.registerCustomCommandNamed("isSBTProxyURLProtocolRegistered") { _ in
            SBTProxyURLProtocol.stubRequests(
                matching: SBTRequestMatch(url: ".*"),
                stubResponse: SBTStubResponse(response: "", returnCode: 0, responseTime: 0)
            )

            let request = URLRequest(url: URL(string: "https://www.subito.it")!)
            let selector = NSSelectorFromString("_protocolClassForRequest:")
            let klass = (URLProtocol.self as AnyObject).perform(selector, with: request)?.takeUnretainedValue()
            let className = klass.map { String(describing: type(of: $0)) } ?? ""

            return NSNumber(value: className == "SBTProxyURLProtocol")
        }

        SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnCLAccuracyAuth") { _ in
            let manager = CLLocationManager()
            return "\(manager.accuracyAuthorization.rawValue)" as NSObject
        }

        SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnCLAuthStatus") { _ in
            let manager = CLLocationManager()
            return "\(manager.authorizationStatus.rawValue)" as NSObject
        }

        SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnUNAuthRequest") { _ in
            let semaphore = DispatchSemaphore(value: 0)
            var authGranted = false

            UNUserNotificationCenter.current().requestAuthorization(options: []) { granted, _ in
                authGranted = granted
                semaphore.signal()
            }

            semaphore.wait()
            return "\(authGranted ? 1 : 0)" as NSObject
        }

        SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnUNAuthStatus") { _ in
            let semaphore = DispatchSemaphore(value: 0)
            var authStatus: UNAuthorizationStatus = .notDetermined

            UNUserNotificationCenter.current().getNotificationSettings { settings in
                authStatus = settings.authorizationStatus
                semaphore.signal()
            }

            semaphore.wait()
            return "\(authStatus.rawValue)" as NSObject
        }

        let didTakeOff = SBTUITestTunnelServer.takeOff()
        print("Tunnel established: \(didTakeOff)")

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
