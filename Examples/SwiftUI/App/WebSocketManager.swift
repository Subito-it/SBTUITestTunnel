// (c) Subito.it proprietary and confidential

import SwiftUI

class WebSocketManager: ObservableObject {
    @Published var connectionStatus = "unknown"
    @Published var networkResult = ""

    private var socket: URLSessionWebSocketTask?
    private var timer: Timer?

    func setup() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.handleTimer()
        }

        let port = UserDefaults.standard.integer(forKey: "websocketport")
        socket = URLSession.shared.webSocketTask(with: URL(string: "ws://localhost:\(port)")!)
        socket?.resume()
    }

    func sendMessage() {
        let message = URLSessionWebSocketTask.Message.string("Hello, world!")
        networkResult = "Send message..."
        socket?.send(message) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.networkResult = "⚠️ WebSocket couldn't send message: \(error)"
                } else {
                    self?.networkResult = "Sent: Hello, world!"
                }
            }
        }
    }

    func receiveMessage() {
        networkResult = "Receive message..."
        socket?.receive { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case let .failure(error):
                    self?.networkResult = "⚠️ WebSocket receive error: \(error)"
                case let .success(message):
                    switch message {
                    case let .string(text):
                        self?.networkResult = "Received text: \(text)"
                    case let .data(data):
                        self?.networkResult = "Received binary data: \(data.count) bytes"
                    @unknown default:
                        self?.networkResult = "Received unexpected message"
                    }
                }
            }
        }
    }

    func sendPing() {
        networkResult = "Send ping..."
        socket?.sendPing { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.networkResult = "⚠️ WebSocket couldn't send ping: \(error)"
                } else {
                    self?.networkResult = "Pong received"
                }
            }
        }
    }

    func disconnect() {
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        networkResult = "Disconnected"
    }

    private func handleTimer() {
        guard let state = socket?.state else { return }

        let label = switch state {
        case .running: "connected"
        case .canceling: "cancelled"
        case .completed: "closed"
        case .suspended: "suspended"
        @unknown default: "unknown"
        }

        if connectionStatus != label {
            connectionStatus = label
        }
    }

    deinit {
        timer?.invalidate()
        socket?.cancel()
    }
}
