//
//  SBTTableViewController.swift
//  SBTUITestTunnel
//
//  Created by Tomas on 14/09/16.
//  Copyright © 2016 Tomas Camin. All rights reserved.
//

import UIKit

class SBTTableViewController: UITableViewController {
    
    private let testList = ["A",
                            "B"]

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = testList[indexPath.row]

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        perform(Selector(testList[indexPath.row]))
    }
}
