// OversizedScrollTargetView.swift
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

// A narrow, tall target (or a short, wide one) exercises visibility relative
// to each viewport dimension, including when the viewport has a larger area.
struct OversizedScrollTargetView: View {
    let horizontal: Bool

    private var target: some View {
        Text("Oversized target")
            .frame(width: horizontal ? 3000 : 100, height: horizontal ? 100 : 3000)
            .background(Color.blue)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Oversized target")
            .accessibilityIdentifier("oversized-target")
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(horizontal ? .horizontal : .vertical) {
                if horizontal {
                    HStack(spacing: 0) {
                        // Expose a sliver initially so XCTest can resolve the
                        // node, while still requiring paging to meet the threshold.
                        Color.clear.frame(width: geometry.size.width * 0.9, height: 100)
                        target
                        Color.clear.frame(width: 1200, height: 100)
                    }
                } else {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 1200)
                        target
                        Color.clear.frame(height: 1200)
                    }
                }
            }
            .accessibilityIdentifier("oversized-scroll")
        }
    }
}
