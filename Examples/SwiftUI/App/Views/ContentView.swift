// ContentView.swift
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
