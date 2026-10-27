// SBTExtensionScrollViewController.swift
//
// Copyright (C) 2026 Subito.it S.r.l (www.subito.it)
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

class SBTExtensionScrollViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupScrollView()
        setupContent()
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.accessibilityIdentifier = "scrollView"
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        contentStackView.alignment = .fill
        scrollView.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }

    private func setupContent() {
        // Add "Content 0" through "Content 19" before the button
        for index in 0 ..< 20 {
            let label = createContentLabel(index: index, prefix: "Content")
            label.accessibilityIdentifier = "pre-content\(index)"
            contentStackView.addArrangedSubview(label)
        }

        // Add the button
        let button = UIButton(type: .system)
        button.setTitle("Button", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.accessibilityIdentifier = "Button"
        contentStackView.addArrangedSubview(button)

        // Add "Content 20" through "Content 39" after the button
        for index in 20 ..< 40 {
            let label = createContentLabel(index: index, prefix: "Content")
            label.accessibilityIdentifier = "before-content\(index)"
            contentStackView.addArrangedSubview(label)
        }
    }

    private func createContentLabel(index: Int, prefix: String) -> UILabel {
        let label = UILabel()
        label.text = "\(prefix) \(index)"
        label.textAlignment = .center
        label.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return label
    }
}
