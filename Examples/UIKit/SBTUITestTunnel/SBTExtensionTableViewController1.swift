// SBTExtensionTableViewController1.swift
//
// Copyright (C) 2019 Subito.it S.r.l (www.subito.it)
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

import UIKit

class SBTExtensionTableViewController1: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "table"
        tableView.rowHeight = 100
        tableView.register(LabelTableViewCell.self, forCellReuseIdentifier: "labelCell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        100
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "labelCell", for: indexPath) as? LabelTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: indexPath.row)
        return cell
    }
}

// MARK: - Custom Cell with accessible label

private final class LabelTableViewCell: UITableViewCell {
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        // Cell is not an accessibility element - it exposes its children
        isAccessibilityElement = false

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17)
        // Label is the accessible element with staticText trait
        label.isAccessibilityElement = true
        label.accessibilityTraits = .staticText
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with index: Int) {
        let text = "Label \(index)"
        label.text = text
        // Set accessibility label so staticTexts["Label X"] can find it
        label.accessibilityLabel = text
        // Set identifier on the cell for scrollContent API
        accessibilityIdentifier = "label_\(index)"
        // Expose only the label as accessible child
        accessibilityElements = [label]
    }
}
