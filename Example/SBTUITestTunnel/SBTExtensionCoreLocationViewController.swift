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
            contentStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
        ])

        replacementDelegate.locationLabel = locationLabel

        backgroundThread?.start()
        onManagerThread {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
        }

        SBTUITestTunnelServer.registerCustomCommandNamed(Self.fixtureCommandName) { [weak self] action in
            self?.performFixtureAction(action as? String)
            return "YES" as NSString
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
    private func performFixtureAction(_ action: String?) {
        switch action {
        case "reassignDelegate":
            onManagerThread { self.locationManager?.delegate = self }
        case "clearDelegateOnLegacyAuthorizationCallback":
            onManagerThread { self.clearsDelegateOnLegacyAuthorizationCallback = true }
        case "holdThenClearDelegate":
            holdManagerThread { self.locationManager?.delegate = nil }
        case "holdThenReplaceDelegate":
            holdManagerThread { self.locationManager?.delegate = self.replacementDelegate }
        default:
            assertionFailure("Unknown Core Location fixture action \(action ?? "nil")")
        }
    }

    // Returns once the manager thread is blocked, so events sent meanwhile queue up behind `work`
    private func holdManagerThread(then work: @escaping () -> Void) {
        let isHolding = DispatchSemaphore(value: 0)
        let block = SBTBlock {
            isHolding.signal()
            Thread.sleep(forTimeInterval: 3.0)
            work()
        }
        block.perform(#selector(SBTBlock.run), on: managerThread, with: nil, waitUntilDone: false)
        isHolding.wait()
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
