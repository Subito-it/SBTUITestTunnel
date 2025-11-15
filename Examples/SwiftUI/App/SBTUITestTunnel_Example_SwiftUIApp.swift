// SBTUITestTunnel_Example_SwiftUIApp.swift
//
// Copyright (C) 2025 Subito.it S.r.l (www.subito.it)
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
import Dispatch
import SwiftUI

#if DEBUG
    import SBTUITestTunnelServer
#endif

@main
struct SBTUITestTunnel_Example_SwiftUIApp: App {
    init() {
        #if DEBUG
            SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnNil") { object in
                UserDefaults.standard.set(object, forKey: "custom_command_test")
                UserDefaults.standard.synchronize()
                return nil
            }

            SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturn123") { object in
                UserDefaults.standard.set(object, forKey: "custom_command_test")
                UserDefaults.standard.synchronize()
                return NSString(string: "123")
            }

            if #available(iOS 14.0, *) {
                SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnCLAccuracyAuth") { _ in
                    let manager = CLLocationManager()
                    return NSString(string: manager.accuracyAuthorization.rawValue.description)
                }

                SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnCLAuthStatus") { _ in
                    NSString(string: CLLocationManager.authorizationStatus().rawValue.description)
                }

                SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnUNAuthRequest") { _ in
                    let semaphore = DispatchSemaphore(value: 0)
                    var authGranted: Bool = false
                    UNUserNotificationCenter.current().requestAuthorization(options: []) { granted, _ in
                        authGranted = granted
                        semaphore.signal()
                    }

                    semaphore.wait()
                    return NSString(string: authGranted.description)
                }

                SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnUNAuthStatus") { _ in
                    let semaphore = DispatchSemaphore(value: 0)
                    var notificationSettings: UNNotificationSettings?
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        notificationSettings = settings
                        semaphore.signal()
                    }

                    semaphore.wait()
                    return NSString(string: notificationSettings?.authorizationStatus.rawValue.description ?? "")
                }
            }
        #endif

        #if DEBUG
            SBTUITestTunnelServer.takeOff()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
