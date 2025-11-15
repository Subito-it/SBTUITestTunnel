// ContentView.swift
//
// Copyright (C) 2023 Subito.it S.r.l (www.subito.it)
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
                    NavigationLink(destination: GenericResultView(test: webSocketTest)) {
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
                    NavigationLink(destination: GenericResultView(test: extensionTest)) {
                        Text(extensionTest.name)
                    }.accessibilityIdentifier(extensionTest.name)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
