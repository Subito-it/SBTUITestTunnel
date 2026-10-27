// WebSocketView.swift
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
        .onDisappear {
            webSocketManager.disconnect()
        }
    }
}
