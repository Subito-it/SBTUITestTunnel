// SBTExtensionCoreLocationViewController.swift
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
import SBTUITestTunnelServer
import UIKit

class SBTExtensionCoreLocationViewController: UIViewController, CLLocationManagerDelegate {
    private static let fixtureCommandName = "coreLocationFixture"

    private let authorizationButton = UIButton()
    private let updateLocationButton = UIButton()
    private let stopLocationUpdateButton = UIButton()
    private let currentLocationButton = UIButton()
    private let statusLabel = UILabel()
    private let statusThreadLabel = UILabel()
    private let preIOS14DeprecatedDelegateStatusLabel = UILabel()
    private let accuracyLabel = UILabel()
    private let locationLabel = UILabel()
    private let locationThreadLabel = UILabel()
    private let currentLocationLabel = UILabel()
    private let errorLabel = UILabel()
    private let errorThreadLabel = UILabel()

    private let backgroundThread: SBTRunLoopThread?
    private let replacementDelegate = SBTReplacementLocationDelegate()
    // Only accessed on managerThread
    private var locationManager: CLLocationManager?
    private var clearsDelegateOnLegacyAuthorizationCallback = false
    // Only accessed on the tunnel's command queue
    private var heldManagerThreadRelease: DispatchSemaphore?
    private var stressFixture: SBTCoreLocationStressFixture?

    private var managerThread: Thread {
        backgroundThread ?? Thread.main
    }

    init(managerOnBackgroundThread: Bool = false) {
        backgroundThread = managerOnBackgroundThread ? SBTRunLoopThread() : nil
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        statusLabel.text = "-"
        statusLabel.textColor = .black
        statusLabel.accessibilityIdentifier = "location_status"

        statusThreadLabel.text = "-"
        statusThreadLabel.textColor = .black
        statusThreadLabel.accessibilityIdentifier = "location_status_thread"

        preIOS14DeprecatedDelegateStatusLabel.text = "-"
        preIOS14DeprecatedDelegateStatusLabel.textColor = .black
        preIOS14DeprecatedDelegateStatusLabel.accessibilityIdentifier = "location_pre_ios14_deprecated_delegate_status"

        accuracyLabel.text = "-"
        accuracyLabel.textColor = .black
        accuracyLabel.accessibilityIdentifier = "location_accuracy"

        locationLabel.text = "-"
        locationLabel.textColor = .black
        locationLabel.accessibilityIdentifier = "location_pos"

        locationThreadLabel.text = "-"
        locationThreadLabel.textColor = .black
        locationThreadLabel.accessibilityIdentifier = "location_thread"

        currentLocationLabel.text = "-"
        currentLocationLabel.textColor = .black
        currentLocationLabel.accessibilityIdentifier = "manager_location"

        errorLabel.text = "-"
        errorLabel.textColor = .black
        errorLabel.accessibilityIdentifier = "location_error"

        errorThreadLabel.text = "-"
        errorThreadLabel.textColor = .black
        errorThreadLabel.accessibilityIdentifier = "location_error_thread"

        authorizationButton.setTitle("Authorization status", for: .normal)
        updateLocationButton.setTitle("Update location", for: .normal)
        stopLocationUpdateButton.setTitle("Stop location updates", for: .normal)
        currentLocationButton.setTitle("Get manager current location", for: .normal)

        for item in [authorizationButton, updateLocationButton, stopLocationUpdateButton, currentLocationButton] {
            item.setTitleColor(.systemBlue, for: .normal)
            item.setTitleColor(.systemRed, for: .highlighted)
        }

        authorizationButton.addTarget(self, action: #selector(authorizationStatusTapped), for: .touchUpInside)
        updateLocationButton.addTarget(self, action: #selector(updateTapped), for: .touchUpInside)
        stopLocationUpdateButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        currentLocationButton.addTarget(self, action: #selector(currentLocationTapped), for: .touchUpInside)

        let statusStack = UIStackView(arrangedSubviews: [authorizationButton, statusLabel, statusThreadLabel, preIOS14DeprecatedDelegateStatusLabel, accuracyLabel])
        let locationStack = UIStackView(arrangedSubviews: [updateLocationButton, stopLocationUpdateButton, currentLocationButton, locationLabel, locationThreadLabel, currentLocationLabel, errorLabel, errorThreadLabel])
        let contentStack = UIStackView(arrangedSubviews: [statusStack, locationStack])

        for item in [statusStack, locationStack, contentStack] {
            item.axis = .vertical
            item.spacing = 16
        }
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])

        replacementDelegate.locationLabel = locationLabel

        backgroundThread?.start()
        onManagerThread {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
        }

        SBTUITestTunnelServer.registerCustomCommandNamed(Self.fixtureCommandName) { [weak self] action in
            (self?.performFixtureAction(action as? String) ?? "NO") as NSString
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard isMovingFromParent else { return }

        SBTUITestTunnelServer.unregisterCommandNamed(Self.fixtureCommandName)
        onManagerThread { self.locationManager = nil }
        backgroundThread?.stop()
    }

    // Invoked on the tunnel's command queue
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
        }
        return "YES"
    }

    // Returns once the manager thread is blocked; events sent before "releaseManagerThread" queue up behind `work`
    private func holdManagerThread(then work: @escaping () -> Void) {
        let isHolding = DispatchSemaphore(value: 0)
        let release = DispatchSemaphore(value: 0)
        heldManagerThreadRelease = release

        let block = SBTBlock {
            isHolding.signal()
            release.wait()
            work()
        }
        block.perform(#selector(SBTBlock.run), on: managerThread, with: nil, waitUntilDone: false)
        isHolding.wait()
    }

    // Returns once callbacks already queued on the manager thread have run and their label updates are applied
    private func waitForQueuedCallbacks() {
        onManagerThread {}
        DispatchQueue.main.sync {}
    }

    @objc func updateTapped(_: Any) {
        onManagerThread { self.locationManager?.startUpdatingLocation() }
    }

    @objc func stopTapped(_: Any) {
        onManagerThread { self.locationManager?.stopUpdatingLocation() }
    }

    @objc func authorizationStatusTapped(_: Any) {
        statusLabel.text = onManagerThread { self.locationManager?.authorizationStatus.description ?? "nil" }
    }

    @objc func currentLocationTapped(_: Any) {
        if let location = onManagerThread({ self.locationManager?.location }) {
            currentLocationLabel.text = "\(location.coordinate.latitude) \(location.coordinate.longitude)"
        } else {
            currentLocationLabel.text = "nil"
        }
    }

    @discardableResult
    private func onManagerThread<T>(_ work: @escaping () -> T) -> T {
        var result: T?
        let block = SBTBlock { result = work() }
        block.perform(#selector(SBTBlock.run), on: managerThread, with: nil, waitUntilDone: true)
        return result!
    }

    private var currentThreadName: String {
        if Thread.isMainThread {
            return "Main"
        }
        return Thread.current === backgroundThread ? "Background" : "Other"
    }
}

@available(iOS 14.0, *)
extension SBTExtensionCoreLocationViewController {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let threadName = currentThreadName
        let status = manager.authorizationStatus.description
        let accuracy = manager.accuracyAuthorization == .reducedAccuracy ? "reducedAccuracy" : "fullAccuracy"
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = status
            self?.statusThreadLabel.text = threadName
            self?.accuracyLabel.text = accuracy
        }
    }
}

extension SBTExtensionCoreLocationViewController {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let threadName = currentThreadName
        if clearsDelegateOnLegacyAuthorizationCallback {
            manager.delegate = nil
        }
        DispatchQueue.main.async { [weak self] in
            self?.preIOS14DeprecatedDelegateStatusLabel.text = status.description
            if #unavailable(iOS 14.0) {
                self?.statusLabel.text = status.description
                self?.statusThreadLabel.text = threadName
            }
        }
    }
}

extension SBTExtensionCoreLocationViewController {
    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let threadName = currentThreadName
        DispatchQueue.main.async { [weak self] in
            self?.locationLabel.text = describe(locations)
            self?.locationThreadLabel.text = threadName
        }
    }
}

extension SBTExtensionCoreLocationViewController {
    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        let threadName = currentThreadName
        let error = error as NSError
        DispatchQueue.main.async { [weak self] in
            self?.errorLabel.text = "\(error.domain) \(error.code)"
            self?.errorThreadLabel.text = threadName
        }
    }
}

extension CLAuthorizationStatus: CustomStringConvertible {
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
    weak var locationLabel: UILabel?

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async { [weak self] in
            self?.locationLabel?.text = "replacement \(describe(locations))"
        }
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

        workers = (0 ..< 4).map { _ in SBTStressWorker(stats: stats) }
        readers = (0 ..< 2).map { _ in
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
