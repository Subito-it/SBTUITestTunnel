// LaunchProbe.swift
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

import Foundation

/// Records the launch ordering so a UI test can inspect exactly when
/// `didFinishLaunching`, `scene(willConnectTo:)` and `takeOff()` ran, and what
/// tunnel-injected state each phase observed.
///
/// The whole point of the repro: a test injects a value into
/// `UserDefaults` from its `launchTunnel` startup block. Whether the app sees
/// that value while it configures itself depends entirely on whether the
/// blocking tunnel handshake (`takeOff`) completed *before* the app read it.
enum LaunchProbe {
    /// Key the test injects during the startup block.
    static let injectedKey = "injected_key"

    /// Ordered log of launch milestones.
    static var events: [String] = []

    /// Value of `injectedKey` observed at the end of `didFinishLaunching`.
    static var valueSeenAtDidFinishLaunching: String?

    /// Value of `injectedKey` observed when the *first* scene built its UI.
    static var valueSeenAtSceneConnection: String?

    /// Value of `injectedKey` observed by *every* scene connection, in order.
    /// The first entry corresponds to `valueSeenAtSceneConnection`; later
    /// entries are additional scenes connected while the app is already running
    /// (multi-window). Used to prove injected state stays visible to scenes that
    /// connect after `takeOff()` has long since returned.
    static var valuesSeenAtSceneConnections: [String] = []

    /// Layer speed observed after the first scene window became key.
    static var windowLayerSpeed: Float = 0

    static func record(_ event: String) {
        events.append(event)
        NSLog("[LaunchProbe] \(event)")
    }

    static func readInjectedValue() -> String {
        UserDefaults.standard.string(forKey: injectedKey) ?? "nil"
    }
}
