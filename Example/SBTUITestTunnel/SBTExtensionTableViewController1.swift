//
//  SBTExtensionTableViewController1.swift
//  SBTUITestTunnel_Example
//
//  Created by tomas on 20/06/2019.
//  Copyright © 2019 Tomas Camin. All rights reserved.
//

import UIKit

class SBTExtensionTableViewController1: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.accessibilityIdentifier = "table"
    }
}
