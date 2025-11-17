// ExtensionViews.swift
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

// MARK: - Extension Table View 1
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

// MARK: - Extension Table View 2
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

// MARK: - Extension Collection View Vertical
struct ExtensionCollectionVerticalView: View {
    private let columns = [GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<100, id: \.self) { index in
                    ZStack {
                        Rectangle()
                            .fill(Color.red)
                            .frame(height: 100)

                        Text("\(index)")
                            .foregroundColor(.white)
                            .accessibilityIdentifier("\(index)")
                            .accessibilityElement()
                    }
                }
            }
            .padding()
        }
        .accessibilityIdentifier("collection")
        .navigationTitle("Collection Vertical")
        .background(Color.green)
    }
}

// MARK: - Extension Collection View Horizontal
struct ExtensionCollectionHorizontalView: View {
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 10) {
                ForEach(0..<100, id: \.self) { index in
                    ZStack {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 100)

                        Text("\(index)")
                            .foregroundColor(.white)
                            .accessibilityIdentifier("\(index)")
                            .accessibilityElement()
                    }
                }
            }
            .padding()
        }
        .accessibilityIdentifier("collection")
        .navigationTitle("Collection Horizontal")
        .background(Color.green)
    }
}

// MARK: - Extension ScrollView
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