// (c) Subito.it proprietary and confidential

import SBTUITestTunnelServer
import UIKit

class SBTWebSocketTestViewController: UIViewController {
    @IBOutlet var networkResult: UITextView!
    @IBOutlet var connectionStatusLabel: UILabel!

    var networkResultString: String = ""
    private var socket: URLSessionWebSocketTask?
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: true)

        networkResult.text = networkResultString

        let port = UserDefaults.standard.integer(forKey: "websocketport")

        socket = URLSession.shared.webSocketTask(with: URL(string: "ws://localhost:\(port)")!)
        socket?.resume()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
        networkResult.text = "Disconnected"
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        let message = URLSessionWebSocketTask.Message.string("Hello, world!")
        socket?.send(message) { error in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                if let error {
                    networkResult.text = "⚠️ WebSocket couldn’t send message: \(error)"
                } else {
                    networkResult.text = "Sent: Hello, world!"
                }
            }
        }
    }

    @IBAction func receiveButtonTapped(_ sender: UIButton) {
        socket?.receive { result in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                switch result {
                case let .failure(error):
                    networkResult.text = "⚠️ WebSocket receive error: \(error)"
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

    @IBAction func pingButtonTapped(_ sender: Any) {
        socket?.sendPing { error in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                if let error {
                    networkResult.text = "⚠️ WebSocket couldn't send ping: \(error)"
                } else {
                    networkResult.text = "Pong received"
                }
            }
        }
    }

    @IBAction func disconnectButtonTapped(_ sender: Any) {
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
