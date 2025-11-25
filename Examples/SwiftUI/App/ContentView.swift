// (c) Subito.it proprietary and confidential

import CoreLocation
import SwiftUI

struct ContentView: View {
    let testManager = TestManager()

    @State private var readyToNavigate: Bool = false

    var body: some View {
        NavigationView {
            List(Array(testManager.testList.enumerated()), id: \.element.name) { index, test in
                switch test {
                case let networkTest as NetworkTest:
                    NavigationLink(destination: NetworkResultView(test: networkTest)) {
                        HStack {
                            Text("[\(index)]")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text(networkTest.name)
                        }
                    }.accessibilityIdentifier(networkTest.name)
                case let webSocketTest as WebSocketTest:
                    NavigationLink(destination: WebSocketView(test: webSocketTest)) {
                        HStack {
                            Text("[\(index)]")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text(webSocketTest.name)
                        }
                    }.accessibilityIdentifier(webSocketTest.name)
                case let autocompleteTest as AutocompleteTest:
                    NavigationLink(destination: GenericResultView(test: autocompleteTest)) {
                        HStack {
                            Text("[\(index)]")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text(autocompleteTest.name)
                        }
                    }.accessibilityIdentifier(autocompleteTest.name)
                case let cookiesTest as CookiesTest:
                    NavigationLink(destination: GenericResultView(test: cookiesTest)) {
                        HStack {
                            Text("[\(index)]")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text(cookiesTest.name)
                        }
                    }.accessibilityIdentifier(cookiesTest.name)
                case let extensionTest as ExtensionTest:
                    NavigationLink(destination: extensionViewFor(test: extensionTest)) {
                        HStack {
                            Text("[\(index)]")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text(extensionTest.name)
                        }
                    }.accessibilityIdentifier(extensionTest.name)
                case let coreLocationTest as CoreLocationTest:
                    NavigationLink(destination: CoreLocationView(test: coreLocationTest)) {
                        HStack {
                            Text("[\(index)]")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text(coreLocationTest.name)
                        }
                    }.accessibilityIdentifier(coreLocationTest.name)
                case let crashTest as CrashTest:
                    NavigationLink(destination: GenericResultView(test: crashTest)) {
                        HStack {
                            Text("[\(index)]")
                                .foregroundColor(.gray)
                                .font(.caption)
                            Text(crashTest.name)
                        }
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

// MARK: - WebSocket View

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
                Button(action: {
                    webSocketManager.sendMessage()
                }) {
                    Text("Send")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button(action: { webSocketManager.receiveMessage() }) {
                    Text("Receive")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button(action: { webSocketManager.sendPing() }) {
                    Text("Ping")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button(action: { webSocketManager.disconnect() }) {
                    Text("Disconnect")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
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
