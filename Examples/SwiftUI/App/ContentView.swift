// ContentView.swift
//
// Copyright (C) 2025 Subito.it S.r.l (www.subito.it)
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

import SwiftUI
import CoreLocation

struct ContentView: View {
    let testManager = TestManager()

    @State private var readyToNavigate: Bool = false

    var body: some View {
        NavigationView {
            List(testManager.testList, id: \.name) { test in
                switch test {
                case let networkTest as NetworkTest:
                    NavigationLink(destination: NetworkResultView(test: networkTest)) {
                        Text(networkTest.name)
                    }.accessibilityIdentifier(networkTest.name)
                case let webSocketTest as WebSocketTest:
                    NavigationLink(destination: WebSocketView(test: webSocketTest)) {
                        Text(webSocketTest.name)
                    }.accessibilityIdentifier(webSocketTest.name)
                case let autocompleteTest as AutocompleteTest:
                    NavigationLink(destination: GenericResultView(test: autocompleteTest)) {
                        Text(autocompleteTest.name)
                    }.accessibilityIdentifier(autocompleteTest.name)
                case let cookiesTest as CookiesTest:
                    NavigationLink(destination: GenericResultView(test: cookiesTest)) {
                        Text(cookiesTest.name)
                    }.accessibilityIdentifier(cookiesTest.name)
                case let extensionTest as ExtensionTest:
                    NavigationLink(destination: extensionViewFor(test: extensionTest)) {
                        Text(extensionTest.name)
                    }.accessibilityIdentifier(extensionTest.name)
                case let coreLocationTest as CoreLocationTest:
                    NavigationLink(destination: CoreLocationView(test: coreLocationTest)) {
                        Text(coreLocationTest.name)
                    }.accessibilityIdentifier(coreLocationTest.name)
                case let crashTest as CrashTest:
                    NavigationLink(destination: GenericResultView(test: crashTest)) {
                        Text(crashTest.name)
                    }.accessibilityIdentifier(crashTest.name)
                default:
                    EmptyView()
                }
            }
            .accessibilityIdentifier("example_list")
            .navigationTitle("SBTUITestTunnel Example")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func extensionViewFor(test: ExtensionTest) -> some View {
        switch test.name {
        case "showExtensionTable1":
            ExtensionTable1View()
        case "showExtensionTable2":
            ExtensionTable2View()
        case "showExtensionCollectionViewVertical":
            ExtensionCollectionVerticalView()
        case "showExtensionCollectionViewHorizontal":
            ExtensionCollectionHorizontalView()
        case "showExtensionScrollView":
            ExtensionScrollView()
        default:
            GenericResultView(test: test)
        }
    }
}

struct NetworkResultView: View {
    let test: NetworkTest

    @State private var isLoading: Bool = true
    @State private var result: String = ""

    var body: some View {
        Group {
            if isLoading {
                ProgressView().accessibilityIdentifier("progress")
            } else {
                ScrollView {
                    Text(result)
                        .accessibilityIdentifier("result")
                        .padding(8)
                        .font(.footnote)
                }
            }
        }.onAppear {
            Task {
                do {
                    result = try await test.execute()
                } catch {
                    result = "Error: \(error.localizedDescription)"
                }
                isLoading = false
            }
        }
    }
}

struct GenericResultView: View {
    let test: any Test

    @State private var isLoading: Bool = true
    @State private var result: String = ""

    var body: some View {
        Group {
            if isLoading {
                ProgressView().accessibilityIdentifier("progress")
            } else {
                ScrollView {
                    Text(result)
                        .accessibilityIdentifier("result")
                        .padding(8)
                        .font(.footnote)
                }
            }
        }.onAppear {
            Task {
                do {
                    switch test {
                    case let webSocketTest as WebSocketTest:
                        result = try await webSocketTest.execute()
                    case let autocompleteTest as AutocompleteTest:
                        result = try await autocompleteTest.execute()
                    case let cookiesTest as CookiesTest:
                        result = try await cookiesTest.execute()
                    case let extensionTest as ExtensionTest:
                        result = try await extensionTest.execute()
                    case let crashTest as CrashTest:
                        result = try await crashTest.execute()
                    default:
                        result = "Unknown test type"
                    }
                } catch {
                    result = "Error: \(error.localizedDescription)"
                }
                isLoading = false
            }
        }
    }
}

class CoreLocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    let locationManager = CLLocationManager()

    @Published var statusText = "-"
    @Published var statusThreadText = "-"
    @Published var locationText = "-"
    @Published var locationThreadText = "-"
    @Published var managerLocationText = "-"

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func authorizationStatusTapped() {
        if #available(iOS 14.0, *) {
            statusText = "\(locationManager.authorizationStatus.description)"
        } else {
            statusText = "\(CLLocationManager.authorizationStatus().description)"
        }
    }

    func updateTapped() {
        locationManager.startUpdatingLocation()
    }

    func stopTapped() {
        locationManager.stopUpdatingLocation()
    }

    func currentLocationTapped() {
        if let location = locationManager.location {
            managerLocationText = "\(location.coordinate.latitude) \(location.coordinate.longitude)"
        } else {
            managerLocationText = "nil"
        }
    }

    @available(iOS 14.0, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let threadName = Thread.isMainThread ? "Main" : "Not main"
        DispatchQueue.main.async { [weak self] in
            self?.statusText = manager.authorizationStatus.description
            self?.statusThreadText = threadName
        }
    }

    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let threadName = Thread.isMainThread ? "Main" : "Not main"
        if #unavailable(iOS 14.0) {
            DispatchQueue.main.async { [weak self] in
                self?.statusText = status.description
                self?.statusThreadText = threadName
            }
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let threadName = Thread.isMainThread ? "Main" : "Not main"
        DispatchQueue.main.async { [weak self] in
            self?.locationText = locations.map { "\($0.coordinate.latitude) \($0.coordinate.longitude)" }.joined(separator: "+")
            self?.locationThreadText = threadName
        }
    }
}

struct CoreLocationView: View {
    let test: CoreLocationTest
    @StateObject private var locationManager = CoreLocationManager()

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                Button("Authorization status") {
                    locationManager.authorizationStatusTapped()
                }
                .foregroundColor(.blue)

                Text(locationManager.statusText)
                    .accessibilityIdentifier("location_status")

                Text(locationManager.statusThreadText)
                    .accessibilityIdentifier("location_status_thread")
            }

            VStack(spacing: 16) {
                Button("Update location") {
                    locationManager.updateTapped()
                }
                .foregroundColor(.blue)

                Button("Stop location updates") {
                    locationManager.stopTapped()
                }
                .foregroundColor(.blue)

                Button("Get manager current location") {
                    locationManager.currentLocationTapped()
                }
                .foregroundColor(.blue)

                Text(locationManager.locationText)
                    .accessibilityIdentifier("location_pos")

                Text(locationManager.locationThreadText)
                    .accessibilityIdentifier("location_thread")

                Text(locationManager.managerLocationText)
                    .accessibilityIdentifier("manager_location")
            }
        }
        .padding()
    }
}

extension CLAuthorizationStatus: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .authorizedAlways: return "authorizedAlways"
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "@unknown"
        }
    }
}

// MARK: - Extension Views
struct ExtensionTable1View: View {
    var body: some View {
        List(0..<100, id: \.self) { index in
            Text("Label\(index)")
                .accessibilityIdentifier("Label\(index)")
        }
        .accessibilityIdentifier("table")
        .navigationTitle("Extension Table 1")
    }
}

struct ExtensionTable2View: View {
    var body: some View {
        List(0..<100, id: \.self) { index in
            Text("\(index)")
                .accessibilityIdentifier("\(index)")
        }
        .accessibilityIdentifier("table")
        .navigationTitle("Extension Table 2")
    }
}

struct ExtensionCollectionVerticalView: View {
    private let columns = [GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<100, id: \.self) { index in
                    Rectangle()
                        .fill(Color.red)
                        .frame(height: 100)
                        .overlay(
                            Text("\(index)")
                                .foregroundColor(.white)
                        )
                        .accessibilityIdentifier("\(index)")
                }
            }
            .padding()
        }
        .accessibilityIdentifier("collection")
        .navigationTitle("Collection Vertical")
        .background(Color.green)
    }
}

struct ExtensionCollectionHorizontalView: View {
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 10) {
                ForEach(0..<100, id: \.self) { index in
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 100)
                        .overlay(
                            Text("\(index)")
                                .foregroundColor(.white)
                        )
                        .accessibilityIdentifier("\(index)")
                }
            }
            .padding()
        }
        .accessibilityIdentifier("collection")
        .navigationTitle("Collection Horizontal")
        .background(Color.green)
    }
}

struct ExtensionScrollView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Add enough content to make scrolling necessary
                ForEach(0..<20, id: \.self) { index in
                    Text("Content \(index)")
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.3))
                }

                // The button that tests will scroll to find
                Button("Button") {
                    // Button action (can be empty for tests)
                }
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .accessibilityIdentifier("Button")

                // Add more content after the button
                ForEach(20..<40, id: \.self) { index in
                    Text("Content \(index)")
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.3))
                }
            }
            .padding()
        }
        .accessibilityIdentifier("scrollView")
        .navigationTitle("Extension ScrollView")
    }
}

// MARK: - WebSocket View
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
        socket?.send(message) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.networkResult = "⚠️ WebSocket couldn't send message: \(error)"
                } else {
                    self?.networkResult = "Sent: Hello, world!"
                }
            }
        }
    }

    func receiveMessage() {
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
        socket?.sendPing { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
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

struct WebSocketView: View {
    let test: WebSocketTest
    @StateObject private var webSocketManager = WebSocketManager()

    var body: some View {
        VStack(spacing: 20) {
            // Connection Status - This needs to be accessible as StaticText for tests
            Text(webSocketManager.connectionStatus)
                .font(.headline)

            // Buttons
            VStack(spacing: 16) {
                Button("Send") {
                    webSocketManager.sendMessage()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Receive") {
                    webSocketManager.receiveMessage()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Ping") {
                    webSocketManager.sendPing()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Disconnect") {
                    webSocketManager.disconnect()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }

            // Result Text - This needs to be accessible as StaticText for tests
            VStack {
                Text(webSocketManager.networkResult)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .frame(minHeight: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)

            Spacer()
        }
        .padding()
        .navigationTitle("WebSocket Test")
        .onAppear {
            webSocketManager.setup()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
