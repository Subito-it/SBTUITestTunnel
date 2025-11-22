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
import UIKit

class SBTExtensionCoreLocationViewController: UIViewController, CLLocationManagerDelegate {
    private let authorizationButton = UIButton()
    private let updateLocationButton = UIButton()
    private let stopLocationUpdateButton = UIButton()
    private let currentLocationButton = UIButton()
    private let statusLabel = UILabel()
    private let statusThreadLabel = UILabel()
    private let locationLabel = UILabel()
    private let locationThreadLabel = UILabel()
    private let currentLocationLabel = UILabel()
    private let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        statusLabel.text = "-"
        statusLabel.textColor = .black
        statusLabel.accessibilityIdentifier = "location_status"

        statusThreadLabel.text = "-"
        statusThreadLabel.textColor = .black
        statusThreadLabel.accessibilityIdentifier = "location_status_thread"

        locationLabel.text = "-"
        locationLabel.textColor = .black
        locationLabel.accessibilityIdentifier = "location_pos"

        locationThreadLabel.text = "-"
        locationThreadLabel.textColor = .black
        locationThreadLabel.accessibilityIdentifier = "location_thread"

        currentLocationLabel.text = "-"
        currentLocationLabel.textColor = .black
        currentLocationLabel.accessibilityIdentifier = "manager_location"

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

        let statusStack = UIStackView(arrangedSubviews: [authorizationButton, statusLabel, statusThreadLabel])
        let locationStack = UIStackView(arrangedSubviews: [updateLocationButton, stopLocationUpdateButton, currentLocationButton, locationLabel, locationThreadLabel, currentLocationLabel])
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

        locationManager.delegate = self
    }

    @objc func updateTapped(_: Any) {
        locationManager.startUpdatingLocation()
    }

    @objc func stopTapped(_: Any) {
        locationManager.stopUpdatingLocation()
    }

    @objc func authorizationStatusTapped(_: Any) {
        if #available(iOS 14.0, *) {
            statusLabel.text = "\(locationManager.authorizationStatus.description)"
        } else {
            statusLabel.text = "\(CLLocationManager.authorizationStatus().description)"
        }
    }

    @objc func currentLocationTapped(_: Any) {
        if let location = locationManager.location {
            currentLocationLabel.text = "\(location.coordinate.latitude) \(location.coordinate.longitude)"
        } else {
            currentLocationLabel.text = "nil"
        }
    }
}

@available(iOS 14.0, *)
extension SBTExtensionCoreLocationViewController {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let threadName = Thread.isMainThread ? "Main" : "Not main"
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = manager.authorizationStatus.description
            self?.statusThreadLabel.text = threadName
        }
    }
}

extension SBTExtensionCoreLocationViewController {
    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let threadName = Thread.isMainThread ? "Main" : "Not main"
        if #unavailable(iOS 14.0) {
            DispatchQueue.main.async { [weak self] in
                self?.statusLabel.text = status.description
                self?.statusThreadLabel.text = threadName
            }
        }
    }
}

extension SBTExtensionCoreLocationViewController {
    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let threadName = Thread.isMainThread ? "Main" : "Not main"
        DispatchQueue.main.async { [weak self] in
            self?.locationLabel.text = locations.map { "\($0.coordinate.latitude) \($0.coordinate.longitude)" }.joined(separator: "+")
            self?.locationThreadLabel.text = threadName
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
