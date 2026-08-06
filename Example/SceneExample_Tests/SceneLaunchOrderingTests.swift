// SceneLaunchOrderingTests.swift
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
import SBTUITestTunnelClient
import UIKit
import XCTest

/// Regression coverage for calling `takeOff()` under the UIScene life cycle.
///
/// The tunnel injects test state (UserDefaults / keychain / filesystem reset)
/// through a *blocking* handshake inside `takeOff()`. Historically `takeOff()`
/// drove that wait by pumping the main run loop, which let UIKit deliver
/// `scene(_:willConnectTo:)` re-entrantly *in the middle of* `takeOff()` —
/// before the injected state landed. A scene that builds its UI at that point
/// reads stale state.
///
/// The recommended integration is to call `takeOff()` at the very start of
/// `application(_:didFinishLaunchingWithOptions:)`. These tests assert that with
/// that placement the handshake fully completes before any other launch callback
/// runs.
final class SceneLaunchOrderingTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = true
        // The first launch on a freshly-booted CI simulator can exceed the 30s
        // default startup timeout (the app is cold, the runtime is warming up),
        // producing a spurious "Waiting for startup block completion timed out"
        // on the first test only. Give the handshake more headroom on CI.
        SBTUITunneledApplication.setConnectionTimeout(90)
    }

    private func launch(takeOffLocation: String, injectedValue: String) -> (seenAtDidFinishLaunching: String?, seenAtSceneConnection: String?, events: [String]) {
        app.launchArguments = [takeOffLocation]
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
            self.app.userDefaultsSetObject(injectedValue as NSString, forKey: LaunchProbeKeys.injectedKey)
        }

        let probe = readProbe()
        return (probe.seenAtDidFinishLaunching, probe.seenAtSceneConnection, probe.events)
    }

    private func readProbe() -> (
        seenAtDidFinishLaunching: String?,
        seenAtSceneConnection: String?,
        valuesSeenAtSceneConnections: [String],
        windowLayerSpeed: Float,
        events: [String]
    ) {
        let raw = app.performCustomCommandNamed("launchProbe", object: nil)
        guard let probe = raw as? [String: Any] else {
            XCTFail("launchProbe returned \(String(describing: raw))")
            return (nil, nil, [], 0, [])
        }
        return (
            probe["seenAtDidFinishLaunching"] as? String,
            probe["seenAtSceneConnection"] as? String,
            (probe["valuesSeenAtSceneConnections"] as? [String]) ?? [],
            (probe["windowLayerSpeed"] as? NSNumber)?.floatValue ?? 0,
            (probe["events"] as? [String]) ?? []
        )
    }

    /// Recommended integration: `takeOff()` at the top of `didFinishLaunching`.
    /// Both the app delegate and the scene must observe the injected value, and
    /// the scene connection must NOT be delivered nested inside `takeOff()`.
    func testTakeOffInAppDelegate_injectedStateVisibleEverywhere() {
        let injectedValue = "injected-\(ProcessInfo.processInfo.globallyUniqueString)"
        let probe = launch(takeOffLocation: SceneAppDelegateArg.appDelegate, injectedValue: injectedValue)
        NSLog("[SceneLaunchOrderingTests] appdelegate-events: \(probe.events)")

        XCTContext.runActivity(named: "didFinishLaunching observes injected value") { _ in
            XCTAssertEqual(probe.seenAtDidFinishLaunching, injectedValue, "events=\(probe.events)")
        }

        XCTContext.runActivity(named: "scene(willConnectTo:) observes injected value") { _ in
            XCTAssertEqual(probe.seenAtSceneConnection, injectedValue, "events=\(probe.events)")
        }

        XCTContext.runActivity(named: "scene connection is not delivered re-entrantly inside takeOff") { _ in
            let takeOffEnd = probe.events.firstIndex(where: { $0.hasPrefix("takeOff:appDelegate:end") })
            let sceneStart = probe.events.firstIndex(where: { $0.hasPrefix("scene:willConnectTo:start") })
            if let takeOffEnd, let sceneStart {
                XCTAssertLessThan(takeOffEnd, sceneStart, "scene connected before takeOff returned; events=\(probe.events)")
            } else {
                XCTFail("missing milestones; events=\(probe.events)")
            }
        }
    }

    /// Deadlock regression: a startup command that performs a *synchronous*
    /// network request served by the tunnel's own stub proxy must complete.
    ///
    /// `takeOff()` deliberately does not service UIKit's main run-loop mode for
    /// the whole handshake. The stub proxy used to deliver responses on the main
    /// queue, so
    /// a startup command that blocked waiting on a stubbed request would deadlock:
    /// the delivery block could never run, the command never returned, the
    /// handshake never finished, and `takeOff` eventually tripped its "Fail
    /// waiting for launch semaphore" assertion. The proxy now delivers on a
    /// background queue; this test injects exactly that shape and asserts the
    /// launch completes and observes the injected state.
    func testTakeOffInAppDelegate_startupCommandWithSyncStubbedRequest_doesNotDeadlock() {
        let injectedValue = "injected-\(ProcessInfo.processInfo.globallyUniqueString)"
        let stubbedBody = "stub-\(ProcessInfo.processInfo.globallyUniqueString)"
        let requestURL = "https://sbtuitesttunnel.test/session"

        app.launchArguments = [SceneAppDelegateArg.appDelegate]
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
            self.app.userDefaultsSetObject(injectedValue as NSString, forKey: LaunchProbeKeys.injectedKey)
            self.app.stubRequests(matching: SBTRequestMatch(url: "sbtuitesttunnel.test/session"),
                                  response: SBTStubResponse(response: stubbedBody))
            // Blocks the command queue on a synchronous stubbed request while
            // `takeOff` holds the main thread — the exact deadlock shape.
            let result = self.app.performCustomCommandNamed("performSyncStubbedRequest", object: requestURL as NSString)
            XCTAssertEqual(result as? String, stubbedBody, "synchronous stubbed startup request did not complete (deadlock)")
        }

        XCTContext.runActivity(named: "launch completed without deadlocking the startup handshake") { _ in
            let probe = readProbe()
            XCTAssertEqual(probe.seenAtDidFinishLaunching, injectedValue, "events=\(probe.events)")
            XCTAssertEqual(probe.seenAtSceneConnection, injectedValue, "events=\(probe.events)")
        }
    }

    func testTakeOffInAppDelegate_startupCommandCanSynchronouslyUseMainThread() throws {
        let animationSpeed = 7
        app.launchArguments = [SceneAppDelegateArg.appDelegate]
        app.launchTunnel {
            XCTAssertTrue(self.app.setUserInterfaceAnimationSpeed(animationSpeed))
        }

        let probe = readProbe()
        XCTAssertEqual(probe.windowLayerSpeed, Float(animationSpeed), "events=\(probe.events)")
        let takeOffEnd = try XCTUnwrap(probe.events.firstIndex(where: { $0.hasPrefix("takeOff:appDelegate:end") }))
        let sceneStart = try XCTUnwrap(probe.events.firstIndex(where: { $0.hasPrefix("scene:willConnectTo:start") }))
        XCTAssertLessThan(takeOffEnd, sceneStart)
    }

    func testAnimationSpeedUpdatesConnectedSceneKeyWindow() throws {
        let animationSpeed = 9
        app.launchArguments = [SceneAppDelegateArg.appDelegate]
        app.launchTunnel()

        XCTAssertTrue(app.setUserInterfaceAnimationSpeed(animationSpeed))
        let rawSpeeds = app.performCustomCommandNamed("keyWindowLayerSpeeds", object: nil)
        let speeds = try XCTUnwrap(rawSpeeds as? [NSNumber])
        XCTAssertFalse(speeds.isEmpty)
        XCTAssertTrue(speeds.allSatisfy { $0.floatValue == Float(animationSpeed) })
    }

    /// Multi-window regression: a *second* scene, connected long after
    /// `takeOff()` has returned, must still observe the injected state.
    ///
    /// The tunnel handshake completes once (guarded by `dispatch_once`). A scene
    /// that connects later must not re-enter or hang on the completed handshake,
    /// or read stale state — it simply sees the state that was injected at
    /// launch. This is the shape (`UIApplicationSupportsMultipleScenes = true`)
    /// that motivated moving `takeOff()` out of the scene delegate.
    func testTakeOffInAppDelegate_secondSceneStillObservesInjectedState() throws {
        // A second concurrent window scene is only created on iPad; on iPhone
        // `requestSceneSessionActivation` is a no-op, so the multi-window path
        // can't be exercised there.
        try XCTSkipUnless(UIDevice.current.userInterfaceIdiom == .pad, "multi-window requires iPad")

        let injectedValue = "injected-\(ProcessInfo.processInfo.globallyUniqueString)"
        app.launchArguments = [SceneAppDelegateArg.appDelegate]
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) {
            self.app.userDefaultsSetObject(injectedValue as NSString, forKey: LaunchProbeKeys.injectedKey)
        }

        XCTContext.runActivity(named: "first scene observes injected value") { _ in
            let probe = readProbe()
            XCTAssertEqual(probe.valuesSeenAtSceneConnections.count, 1, "events=\(probe.events)")
            XCTAssertEqual(probe.valuesSeenAtSceneConnections.first, injectedValue, "events=\(probe.events)")
        }

        _ = app.performCustomCommandNamed("activateSecondScene", object: nil)

        let secondSceneConnected = expectation(description: "second scene connected")
        var lastProbe = readProbe()
        // Poll the probe until a second scene connection is recorded. The window
        // is generous (≈20s) because CI runners are considerably slower than a
        // local machine at spinning up a second window scene.
        for _ in 0..<80 where lastProbe.valuesSeenAtSceneConnections.count < 2 {
            usleep(250_000)
            lastProbe = readProbe()
        }
        if lastProbe.valuesSeenAtSceneConnections.count >= 2 {
            secondSceneConnected.fulfill()
        }
        wait(for: [secondSceneConnected], timeout: 10)

        NSLog("[SceneLaunchOrderingTests] multiscene-events: \(lastProbe.events)")

        XCTContext.runActivity(named: "second scene observes the same injected value") { _ in
            XCTAssertGreaterThanOrEqual(lastProbe.valuesSeenAtSceneConnections.count, 2, "second scene never connected; events=\(lastProbe.events)")
            for (index, seen) in lastProbe.valuesSeenAtSceneConnections.enumerated() {
                XCTAssertEqual(seen, injectedValue, "scene #\(index) saw stale state; events=\(lastProbe.events)")
            }
        }

        XCTContext.runActivity(named: "second scene does not re-enter takeOff") { _ in
            let takeOffStarts = lastProbe.events.filter { $0.hasPrefix("takeOff:") && $0.hasSuffix(":start") }
            XCTAssertEqual(takeOffStarts.count, 1, "takeOff ran more than once; events=\(lastProbe.events)")
        }
    }
}

enum LaunchProbeKeys {
    static let injectedKey = "injected_key"
}

enum SceneAppDelegateArg {
    static let appDelegate = "TAKEOFF_IN_APPDELEGATE"
    static let scene = "TAKEOFF_IN_SCENE"
}
