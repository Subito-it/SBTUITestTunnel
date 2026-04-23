// SBTNetworkTestViewController.swift
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

import UIKit

class SBTNetworkTestViewController: UIViewController {
    private let networkResult = UITextView()
    var networkResultString: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        networkResult.text = networkResultString
    }

    private func setupUI() {
        networkResult.translatesAutoresizingMaskIntoConstraints = false
        networkResult.isEditable = false
        networkResult.isSelectable = false
        networkResult.font = .systemFont(ofSize: 14)
        networkResult.accessibilityIdentifier = "result"
        view.addSubview(networkResult)

        NSLayoutConstraint.activate([
            networkResult.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            networkResult.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            networkResult.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            networkResult.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
