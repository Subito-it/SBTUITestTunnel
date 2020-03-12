//
//  SBTExtensionViewController4.swift
//  SBTUITestTunnel_Example
//
//  Created by tomas on 12/03/2020.
//  Copyright © 2020 Tomas Camin. All rights reserved.
//

import UIKit
import CoreLocation

class SBTExtensionViewController4: UIViewController {
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func authorizationStatusTapped(_ sender: Any) {
        statusLabel.text = "\(CLLocationManager.authorizationStatus().rawValue)"
    }
}
