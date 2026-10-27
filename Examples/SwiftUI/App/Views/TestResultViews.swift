// TestResultViews.swift
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
        }.task {
            isLoading = true
            do {
                let response = try await test.execute()
                guard !Task.isCancelled else { return }
                result = response
            } catch {
                guard !Task.isCancelled else { return }
                result = "Error: \(error.localizedDescription)"
            }
            isLoading = false
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
        }.task {
            isLoading = true
            do {
                let response: String
                switch test {
                case let cookiesTest as CookiesTest:
                    response = try await cookiesTest.execute()
                case let extensionTest as ExtensionTest:
                    response = try await extensionTest.execute()
                case let crashTest as CrashTest:
                    response = try await crashTest.execute()
                default:
                    response = "Unknown test type"
                }
                guard !Task.isCancelled else { return }
                result = response
            } catch {
                guard !Task.isCancelled else { return }
                result = "Error: \(error.localizedDescription)"
            }
            guard !Task.isCancelled else { return }
            isLoading = false
        }
    }
}

struct AutocompleteView: View {
    @State private var text = ""

    var body: some View {
        VStack {
            TextField("Text", text: $text)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(false)
                .accessibilityIdentifier("autocompleteTextField")
            Spacer()
        }
        .padding()
        .navigationTitle("Autocomplete")
    }
}
