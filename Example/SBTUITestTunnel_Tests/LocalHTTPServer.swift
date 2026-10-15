// LocalHTTPServer.swift
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

import Foundation
import Network

/// HTTP server on the loopback interface that serves canned responses and counts the requests it receives per path
final class LocalHTTPServer {
    struct Response {
        var statusCode: Int
        var headers: [String: String] = [:]
        var body: String = ""
        /// Resets the connection before the last chunk of the body, so the body transfer fails
        var failsBodyTransfer = false
    }

    private let listener: NWListener
    private let queue = DispatchQueue(label: "LocalHTTPServer")
    private let routes: [String: Response]
    private var hitsByPath: [String: Int] = [:]

    init(routes: [String: Response]) throws {
        self.routes = routes

        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: .any)
        listener = try NWListener(using: parameters)

        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            if case .ready = state {
                ready.signal()
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }
        listener.start(queue: queue)

        guard ready.wait(timeout: .now() + 5.0) == .success, listener.port != nil else {
            listener.cancel()
            throw URLError(.cannotConnectToHost)
        }
    }

    deinit {
        listener.cancel()
    }

    var baseURL: String {
        "http://127.0.0.1:\(listener.port!.rawValue)"
    }

    func url(_ path: String) -> String {
        baseURL + path
    }

    func hits(_ path: String) -> Int {
        queue.sync { hitsByPath[path, default: 0] }
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveRequestHead(on: connection, buffer: Data())
    }

    private func receiveRequestHead(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            var buffer = buffer
            if let data {
                buffer.append(data)
            }

            if let headEnd = buffer.range(of: Data("\r\n\r\n".utf8)) {
                respond(toRequestHead: buffer[..<headEnd.lowerBound], on: connection)
            } else if isComplete || error != nil {
                connection.cancel()
            } else {
                receiveRequestHead(on: connection, buffer: buffer)
            }
        }
    }

    private func respond(toRequestHead head: Data, on connection: NWConnection) {
        let requestLine = String(decoding: head, as: UTF8.self).components(separatedBy: "\r\n").first ?? ""
        let requestLineParts = requestLine.split(separator: " ")
        let path = requestLineParts.count > 1 ? String(requestLineParts[1]) : "/"

        hitsByPath[path, default: 0] += 1

        let response = routes[path] ?? Response(statusCode: 404)
        var body = Data(response.body.utf8)
        var headers = response.headers
        headers["Content-Type"] = headers["Content-Type"] ?? "text/plain"
        if response.failsBodyTransfer {
            headers["Transfer-Encoding"] = "chunked"
            body = Data("\(String(body.count, radix: 16))\r\n".utf8) + body + Data("\r\n".utf8)
        } else {
            headers["Content-Length"] = "\(body.count)"
        }
        headers["Connection"] = "close"

        var responseHead = "HTTP/1.1 \(response.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))\r\n"
        for (name, value) in headers {
            responseHead += "\(name): \(value)\r\n"
        }
        responseHead += "\r\n"

        connection.send(content: Data(responseHead.utf8) + body, completion: .contentProcessed { _ in
            if response.failsBodyTransfer {
                connection.forceCancel()
            } else {
                connection.cancel()
            }
        })
    }
}
