// SBTWebSocketTestViewController.swift
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

import SBTUITestTunnelServer
import UIKit

class SBTWebSocketTestViewController: UIViewController {
    private let networkResult = UITextView()
    private let connectionStatusLabel = UILabel()
    private let sendButton = UIButton(type: .system)
    private let receiveButton = UIButton(type: .system)
    private let pingButton = UIButton(type: .system)
    private let disconnectButton = UIButton(type: .system)
    private let statusTitleLabel = UILabel()

    var networkResultString: String = ""
    private var socket: URLSessionWebSocketTask?
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        networkResult.text = networkResultString
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(handleTimer),
            userInfo: nil,
            repeats: true
        )

        let port = UserDefaults.standard.integer(forKey: "websocketport")

        // Replace with wss://echo.websocket.org to live test
        let url = URL(string: "ws://localhost:\(port)")!

        socket = URLSession.shared.webSocketTask(with: url)
        socket?.resume()
    }

    private func setupUI() {
        // Send button
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)

        // Receive button
        receiveButton.setTitle("Receive", for: .normal)
        receiveButton.addTarget(self, action: #selector(receiveButtonTapped), for: .touchUpInside)

        // Ping button
        pingButton.setTitle("Ping", for: .normal)
        pingButton.addTarget(self, action: #selector(pingButtonTapped), for: .touchUpInside)

        // Disconnect button
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.addTarget(self, action: #selector(disconnectButtonTapped), for: .touchUpInside)

        // Status title label
        statusTitleLabel.text = "Connection status:"
        statusTitleLabel.font = .boldSystemFont(ofSize: 17)

        // Connection status label
        connectionStatusLabel.text = "-"
        connectionStatusLabel.font = .systemFont(ofSize: 17)

        // Network result text view
        networkResult.isEditable = false
        networkResult.isSelectable = false
        networkResult.font = .systemFont(ofSize: 14)
        networkResult.accessibilityIdentifier = "result"

        // Add all views
        let buttonStack = UIStackView(arrangedSubviews: [sendButton, receiveButton, pingButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 40

        let statusStack = UIStackView(arrangedSubviews: [statusTitleLabel, connectionStatusLabel])
        statusStack.axis = .horizontal
        statusStack.spacing = 8

        let views: [UIView] = [buttonStack, disconnectButton, statusStack, networkResult]
        for item in views {
            item.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(item)
        }

        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            disconnectButton.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 8),
            disconnectButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            statusStack.topAnchor.constraint(equalTo: disconnectButton.bottomAnchor, constant: 7),
            statusStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            networkResult.topAnchor.constraint(equalTo: statusStack.bottomAnchor, constant: 30),
            networkResult.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            networkResult.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            networkResult.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    @objc private func sendButtonTapped(_ sender: UIButton) {
        let message = URLSessionWebSocketTask.Message.string("Hello, world!")
        socket?.send(message) { error in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                if let error {
                    networkResult.text = "WebSocket couldn't send message: \(error)"
                } else {
                    networkResult.text = "Sent: Hello, world!"
                }
            }
        }
    }

    @objc private func receiveButtonTapped(_ sender: UIButton) {
        socket?.receive { result in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                switch result {
                case let .failure(error):
                    networkResult.text = "WebSocket receive error: \(error)"
                case let .success(message):
                    switch message {
                    case let .string(text):
                        networkResult.text = "Received text: \(text)"
                    case let .data(data):
                        networkResult.text = "Received binary data: \(data.count) bytes"
                    @unknown default:
                        networkResult.text = "Received unexpected message"
                    }
                }
            }
        }
    }

    @objc private func pingButtonTapped(_ sender: Any) {
        socket?.sendPing { error in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                if let error {
                    networkResult.text = "WebSocket couldn't send ping: \(error)"
                } else {
                    networkResult.text = "Pong received"
                }
            }
        }

        // This is required to ensure there is an open receive loop after sending a ping
        socket?.receive { result in
            print(#function, result)
        }
    }

    @objc private func disconnectButtonTapped(_ sender: Any) {
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        networkResult.text = "Disconnected"
    }

    @objc func handleTimer() {
        guard let state = socket?.state else { return }

        let label = switch state {
        case .running: "connected"
        case .canceling: "cancelled"
        case .completed: "closed"
        case .suspended: "suspended"
        @unknown default: "unknown"
        }

        if connectionStatusLabel.text != label {
            connectionStatusLabel.text = label
        }
    }
}
