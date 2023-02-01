//
//  SBTUITestTunnel_Example_SwiftUIApp.swift
//  SBTUITestTunnel_Example_SwiftUI
//
//  Created by Marco Pagliari on 01/02/23.
//

import SwiftUI
import Dispatch
import CoreLocation

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
            SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnCLAccuracyAuth") { object in
                let manager = CLLocationManager()
                return NSString(string: manager.accuracyAuthorization.rawValue.description)
            }

            SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnCLAuthStatus") { object in
                return NSString(string: CLLocationManager.authorizationStatus().rawValue.description)
            }

            SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnUNAuthRequest") { object in
                let semaphore = DispatchSemaphore(value: 0)
                var authGranted: Bool = false
                UNUserNotificationCenter.current().requestAuthorization(options: []) { granted, error in
                    authGranted = granted
                    semaphore.signal()
                }

                semaphore.wait()
                return NSString(string: authGranted.description)
            }

            SBTUITestTunnelServer.registerCustomCommandNamed("myCustomCommandReturnUNAuthStatus") { object in
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
