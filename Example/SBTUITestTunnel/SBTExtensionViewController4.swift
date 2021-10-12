//
//  SBTExtensionViewController4.swift
//  SBTUITestTunnel_Example
//
//  Created by tomas on 12/03/2020.
//  Copyright © 2020 Tomas Camin. All rights reserved.
//

import UIKit
import CoreLocation

class SBTExtensionViewController4: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!

    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func updateTapped(_ sender: Any) {
        locationManager.startUpdatingLocation()
    }

    @IBAction func stopTapped(_ sender: Any) {
        locationManager.stopUpdatingLocation()
    }
    
    @IBAction func authorizationStatusTapped(_ sender: Any) {
        statusLabel.text = "\(CLLocationManager.authorizationStatus().rawValue)"
    }
}

extension SBTExtensionViewController4 {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async { [weak self] in
            self?.locationLabel.text = locations.map { "\($0.coordinate.latitude) \($0.coordinate.longitude)" }.joined(separator: "+")
        }
    }
}
