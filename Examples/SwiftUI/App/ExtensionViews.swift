// (c) Subito.it proprietary and confidential

import SwiftUI

// MARK: - Extension Table View 1

struct ExtensionTable1View: View {
    var body: some View {
        List(0 ..< 100, id: \.self) { index in
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
        List(0 ..< 100, id: \.self) { index in
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
                ForEach(0 ..< 100, id: \.self) { index in
                    Button(action: {}) {
                        Label("\(index)", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("ExtensionCollectionVerticalView_Button_\(index)")
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
                ForEach(0 ..< 100, id: \.self) { index in
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 100)
                        .overlay(
                            Text("\(index)")
                                .foregroundColor(.white)
                                .accessibilityAddTraits(.isStaticText)
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

// MARK: - Extension ScrollView

struct ExtensionScrollView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Add enough content to make scrolling necessary
                ForEach(0 ..< 20, id: \.self) { index in
                    Text("Content \(index)")
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.3))
                        .accessibilityIdentifier("pre-content\(index)")
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
                ForEach(20 ..< 40, id: \.self) { index in
                    Text("Content \(index)")
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.3))
                        .accessibilityIdentifier("before-content\(index)")
                }
            }
            .padding()
        }
        .accessibilityIdentifier("scrollView")
        .navigationTitle("Extension ScrollView")
    }
}
