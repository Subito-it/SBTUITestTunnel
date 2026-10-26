// CoreLocationView.swift
//
// Copyright (C) 2026 Subito.it S.r.l (www.subito.it)
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
import SBTUITestTunnelServer
import SwiftUI

/// Keeps the same manager-thread and delegate fixtures as the UIKit example.
final class CoreLocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private static let fixtureCommandName = "coreLocationFixture"

    @Published var statusText = "-"
    @Published var statusThreadText = "-"
    @Published var legacyStatusText = "-"
    @Published var accuracyText = "-"
    @Published var locationText = "-"
    @Published var locationThreadText = "-"
    @Published var managerLocationText = "-"
    @Published var errorText = "-"
    @Published var errorThreadText = "-"

    private let managerOnBackgroundThread: Bool
    private var backgroundThread: SBTRunLoopThread?
    private let replacementDelegate = SBTReplacementLocationDelegate()
    // Accessed on managerThread, including delegate callbacks.
    private var locationManager: CLLocationManager?
    private var clearsDelegateOnLegacyAuthorizationCallback = false
    // Accessed on the tunnel's command queue.
    private var heldManagerThreadRelease: DispatchSemaphore?
    private var stressFixture: SBTCoreLocationStressFixture?
    private var started = false

    private var managerThread: Thread {
        backgroundThread ?? Thread.main
    }

    init(managerOnBackgroundThread: Bool) {
        self.managerOnBackgroundThread = managerOnBackgroundThread
        super.init()
        replacementDelegate.onLocation = { [weak self] locations in
            self?.locationText = "replacement \(describe(locations))"
        }
    }

    func start() {
        guard !started else { return }
        started = true
        backgroundThread = managerOnBackgroundThread ? SBTRunLoopThread() : nil
        backgroundThread?.start()
        onManagerThread {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
        }
        SBTUITestTunnelServer.registerCustomCommandNamed(Self.fixtureCommandName) { [weak self] action in
            (self?.performFixtureAction(action as? String) ?? "NO") as NSString
        }
    }

    func stop() {
        guard started else { return }
        started = false
        SBTUITestTunnelServer.unregisterCommandNamed(Self.fixtureCommandName)
        heldManagerThreadRelease?.signal()
        heldManagerThreadRelease = nil
        _ = stressFixture?.stop()
        stressFixture = nil
        onManagerThread {
            self.locationManager?.stopUpdatingLocation()
            self.locationManager?.delegate = nil
            self.locationManager = nil
        }
        backgroundThread?.stop()
    }

    private func performFixtureAction(_ action: String?) -> String {
        switch action {
        case "reassignDelegate":
            onManagerThread { self.locationManager?.delegate = self }
        case "clearDelegate":
            onManagerThread { self.locationManager?.delegate = nil }
        case "assignThenClearDelegate":
            onManagerThread {
                self.locationManager?.delegate = self
                self.locationManager?.delegate = nil
            }
            waitForQueuedCallbacks()
        case "clearDelegateOnLegacyAuthorizationCallback":
            onManagerThread { self.clearsDelegateOnLegacyAuthorizationCallback = true }
        case "holdThenClearDelegate":
            holdManagerThread { self.locationManager?.delegate = nil }
        case "holdThenReplaceDelegate":
            holdManagerThread { self.locationManager?.delegate = self.replacementDelegate }
        case "releaseManagerThread":
            heldManagerThreadRelease?.signal()
            heldManagerThreadRelease = nil
            waitForQueuedCallbacks()
        case "waitForQueuedCallbacks":
            waitForQueuedCallbacks()
        case "startStress":
            stressFixture = SBTCoreLocationStressFixture()
        case "stopStress":
            defer { stressFixture = nil }
            return stressFixture?.stop() ?? "NO"
        default:
            assertionFailure("Unknown Core Location fixture action \(action ?? "nil")")
            return "NO"
        }
        return "YES"
    }

    private func holdManagerThread(then work: @escaping () -> Void) {
        let isHolding = DispatchSemaphore(value: 0)
        let release = DispatchSemaphore(value: 0)
        heldManagerThreadRelease = release
        SBTBlock {
            isHolding.signal()
            release.wait()
            work()
        }.perform(#selector(SBTBlock.run), on: managerThread, with: nil, waitUntilDone: false)
        isHolding.wait()
    }

    private func waitForQueuedCallbacks() {
        onManagerThread {}
        DispatchQueue.main.sync {}
    }

    func authorizationStatusTapped() {
        statusText = onManagerThread { self.locationManager?.authorizationStatus.description ?? "nil" }
    }

    func updateTapped() {
        onManagerThread { self.locationManager?.startUpdatingLocation() }
    }

    func stopTapped() {
        onManagerThread { self.locationManager?.stopUpdatingLocation() }
    }

    func currentLocationTapped() {
        if let location = onManagerThread({ self.locationManager?.location }) {
            managerLocationText = "\(location.coordinate.latitude) \(location.coordinate.longitude)"
        } else {
            managerLocationText = "nil"
        }
    }

    @discardableResult
    private func onManagerThread<T>(_ work: @escaping () -> T) -> T {
        var result: T?
        SBTBlock { result = work() }.perform(#selector(SBTBlock.run), on: managerThread, with: nil, waitUntilDone: true)
        return result!
    }

    private var currentThreadName: String {
        if Thread.isMainThread {
            return "Main"
        }
        return Thread.current === backgroundThread ? "Background" : "Other"
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let threadName = currentThreadName
        let status = manager.authorizationStatus.description
        let accuracy = manager.accuracyAuthorization == .reducedAccuracy ? "reducedAccuracy" : "fullAccuracy"
        DispatchQueue.main.async { [weak self] in
            self?.statusText = status
            self?.statusThreadText = threadName
            self?.accuracyText = accuracy
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if clearsDelegateOnLegacyAuthorizationCallback {
            manager.delegate = nil
        }
        DispatchQueue.main.async { [weak self] in
            self?.legacyStatusText = status.description
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let threadName = currentThreadName
        DispatchQueue.main.async { [weak self] in
            self?.locationText = describe(locations)
            self?.locationThreadText = threadName
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        let threadName = currentThreadName
        let error = error as NSError
        DispatchQueue.main.async { [weak self] in
            self?.errorText = "\(error.domain) \(error.code)"
            self?.errorThreadText = threadName
        }
    }
}

struct CoreLocationView: View {
    @StateObject private var locationManager: CoreLocationManager

    init(test: CoreLocationTest) {
        _locationManager = StateObject(wrappedValue: CoreLocationManager(
            managerOnBackgroundThread: test.name == "showCoreLocationViewControllerOnBackgroundThread"
        ))
    }

    var body: some View {
        VStack(spacing: 8) {
            Button("Authorization status") { locationManager.authorizationStatusTapped() }
            Text(locationManager.statusText).accessibilityIdentifier("location_status")
            Text(locationManager.statusThreadText).accessibilityIdentifier("location_status_thread")
            Text(locationManager.legacyStatusText).accessibilityIdentifier("location_pre_ios14_deprecated_delegate_status")
            Text(locationManager.accuracyText).accessibilityIdentifier("location_accuracy")
            Button("Update location") { locationManager.updateTapped() }
            Button("Stop location updates") { locationManager.stopTapped() }
            Button("Get manager current location") { locationManager.currentLocationTapped() }
            Text(locationManager.locationText).accessibilityIdentifier("location_pos")
            Text(locationManager.locationThreadText).accessibilityIdentifier("location_thread")
            Text(locationManager.managerLocationText).accessibilityIdentifier("manager_location")
            Text(locationManager.errorText).accessibilityIdentifier("location_error")
            Text(locationManager.errorThreadText).accessibilityIdentifier("location_error_thread")
        }
        .padding()
        .onAppear { locationManager.start() }
        .onDisappear { locationManager.stop() }
    }
}

extension CLAuthorizationStatus: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .authorizedAlways: return "authorizedAlways"
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "@unknown"
        }
    }
}

private final class SBTReplacementLocationDelegate: NSObject, CLLocationManagerDelegate {
    var onLocation: (([CLLocation]) -> Void)?

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async { [weak self] in self?.onLocation?(locations) }
    }
}

private func describe(_ locations: [CLLocation]) -> String {
    locations.map { "\($0.coordinate.latitude) \($0.coordinate.longitude)" }.joined(separator: "+")
}

/// Core Location delivers delegate callbacks through the run loop of the thread that created the manager.
private final class SBTRunLoopThread: Thread {
    override func main() {
        // Without an input source run(mode:before:) returns immediately and the loop would spin
        RunLoop.current.add(Port(), forMode: .default)

        while !isCancelled {
            autoreleasepool {
                _ = RunLoop.current.run(mode: .default, before: .distantFuture)
            }
        }
    }

    func stop() {
        perform(#selector(cancel), on: self, with: nil, waitUntilDone: false)
    }
}

private final class SBTBlock: NSObject {
    private let block: () -> Void

    init(_ block: @escaping () -> Void) {
        self.block = block
    }

    @objc func run() {
        block()
    }
}

/// Hammers the stubbed Core Location state from several threads while the test drives the server.
private final class SBTCoreLocationStressFixture {
    private let stats: SBTStressStats
    private let workers: [SBTStressWorker]
    private let readers: [Thread]
    private let readersFinished: DispatchGroup

    init() {
        let stats = SBTStressStats()
        let readersFinished = DispatchGroup()
        self.stats = stats
        self.readersFinished = readersFinished

        self.workers = (0 ..< 4).map { _ in SBTStressWorker(stats: stats) }
        self.readers = (0 ..< 2).map { _ in
            Thread {
                // Never given a delegate, so it only exercises the getters
                let manager = CLLocationManager()
                while !Thread.current.isCancelled {
                    SBTStressWorker.validateStubbedState(of: manager, stats: stats)
                    _ = CLLocationManager.locationServicesEnabled()
                    stats.increment("reads")
                }
                readersFinished.leave()
            }
        }

        workers.forEach { $0.start() }
        for reader in readers {
            readersFinished.enter()
            reader.start()
        }
    }

    func stop() -> String {
        workers.forEach { $0.stop() }
        readers.forEach { $0.cancel() }
        readersFinished.wait()

        return stats.summary
    }
}

private final class SBTStressStats {
    private let lock = NSLock()
    private var counts = [String: Int]()

    func increment(_ key: String) {
        lock.lock()
        counts[key, default: 0] += 1
        lock.unlock()
    }

    var summary: String {
        lock.lock()
        defer { lock.unlock() }
        return ["callbacks", "reads", "wrongThread", "invalidValue"].map { "\($0)=\(counts[$0, default: 0])" }.joined(separator: ";")
    }
}

private final class SBTStressWorker: NSObject, CLLocationManagerDelegate {
    private let thread = SBTRunLoopThread()
    private let stats: SBTStressStats
    // Only accessed on thread
    private var manager: CLLocationManager?
    private var timer: Timer?
    private var iteration = 0

    init(stats: SBTStressStats) {
        self.stats = stats
    }

    func start() {
        thread.start()
        SBTBlock { self.startChurning() }.perform(#selector(SBTBlock.run), on: thread, with: nil, waitUntilDone: false)
    }

    private func startChurning() {
        manager = makeManager()
        timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { [unowned self] _ in churn() }
    }

    func stop() {
        // Once the delegate is cleared, callbacks still queued on the thread find no delegate and are dropped
        SBTBlock {
            self.timer?.invalidate()
            self.timer = nil
            self.manager?.delegate = nil
            self.manager = nil
        }.perform(#selector(SBTBlock.run), on: thread, with: nil, waitUntilDone: true)
        thread.stop()
    }

    private func makeManager() -> CLLocationManager {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.startUpdatingLocation()
        return manager
    }

    private func churn() {
        iteration += 1
        if iteration % 25 == 0 {
            // The replaced manager deallocates, dropping its weak entries from the stub's maps
            manager = makeManager()
            return
        }

        switch iteration % 4 {
        case 0: manager?.stopUpdatingLocation()
        case 1: manager?.startUpdatingLocation()
        case 2: manager?.delegate = nil
        default:
            manager?.delegate = self
            manager?.startUpdatingLocation()
        }
    }

    private func record(_ manager: CLLocationManager) {
        stats.increment("callbacks")
        if Thread.current !== thread {
            stats.increment("wrongThread")
        }
        Self.validateStubbedState(of: manager, stats: stats)
    }

    /// The test only stubs locations whose latitude equals their longitude.
    static func validateStubbedState(of manager: CLLocationManager, stats: SBTStressStats) {
        let validStatuses: [CLAuthorizationStatus] = [.notDetermined, .restricted, .denied, .authorizedAlways, .authorizedWhenInUse]
        let validAccuracies: [CLAccuracyAuthorization] = [.fullAccuracy, .reducedAccuracy]

        if !validStatuses.contains(manager.authorizationStatus) || !validAccuracies.contains(manager.accuracyAuthorization) {
            stats.increment("invalidValue")
        }
        if let location = manager.location, location.coordinate.latitude != location.coordinate.longitude {
            stats.increment("invalidValue")
        }
    }

    // Each callback reenters the stub before returning

    func locationManager(_ manager: CLLocationManager, didUpdateLocations _: [CLLocation]) {
        record(manager)
        manager.stopUpdatingLocation()
        manager.delegate = nil
        manager.delegate = self
        manager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        record(manager)
        // Reassigning the delegate here would queue another authorization callback, forever
        manager.stopUpdatingLocation()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError _: Error) {
        record(manager)
        manager.delegate = nil
        manager.delegate = self
    }
}
