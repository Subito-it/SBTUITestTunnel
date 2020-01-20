//
//  SBTExtensionTableViewController2.swift

//  SBTUITestTunnel_Example
//
//  Created by tomas on 20/06/2019.
//  Copyright © 2019 Tomas Camin. All rights reserved.
//

import UIKit

class SBTExtensionTableViewController2: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 150
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        20
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "reuseIdentifier")
        
        cell.textLabel?.text = "\(indexPath.row)"
        
        return cell
    }
}
