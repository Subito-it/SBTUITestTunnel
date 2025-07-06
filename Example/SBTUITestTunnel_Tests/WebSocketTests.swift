// WebSocketTests.swift
//
// Copyright (C) 2016 Subito.it S.r.l (www.subito.it)
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
import SBTUITestTunnelClient
import XCTest

class WebSocketTests: XCTestCase {
    func testWebSocket() {
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) { [unowned self] in
            let port = app.launchWebSocket(identifier: "some-id")
            app.userDefaultsRegisterDefaults(["websocketport": port])
            app.stubWebSocketReceiveMessage(identifier: "some-id", responseData: Data("Hello, world!".utf8))
        }

        XCTContext.runActivity(named: "Test connection") { _ in
            app.cells["executeWebSocket"].tap()
            
            wait { self.app.staticTexts["connected"].exists }
        }
        
        XCTContext.runActivity(named: "Test launch block stubbing") { _ in
            app.buttons["Receive"].tap()
            
            wait { self.app.staticTexts["Received text: Hello, world!"].exists }
        }
                
        XCTContext.runActivity(named: "Test message flushing") { _ in
            app.buttons["Send"].tap()
            wait { self.app.staticTexts["Sent: Hello, world!"].exists }
            app.buttons["Receive"].tap()
            
            let messagesForUnknownIdentifier = app.flushWebSocketMessages(identifier: "not-exist-id")
            XCTAssertEqual(messagesForUnknownIdentifier.count, 0)
            
            let messages = app.flushWebSocketMessages(identifier: "some-id")
            XCTAssertEqual(messages.count, 1)
            XCTAssertEqual(messages[0], Data("Hello, world!".utf8))
            
            let messagesAfterFlush = app.flushWebSocketMessages(identifier: "some-id")
            XCTAssertEqual(messagesAfterFlush.count, 0)
        }
        
        XCTContext.runActivity(named: "Test sendWebSocket message is received instead of receive message") { _ in
            app.stubWebSocketReceiveMessage(identifier: "some-id", responseData: Data("Receive should not be sent!".utf8))
            
            app.sendWebSocket(message: Data("Hello world2!".utf8), identifier: "some-id")
            
            app.buttons["Receive"].tap()
            
            wait { self.app.staticTexts["Received text: Hello world2!"].exists }
        }
    }
    
    func testWebSocketPingPong() {
        app.launchTunnel(withOptions: [SBTUITunneledApplicationLaunchOptionResetFilesystem]) { [unowned self] in
            let port = app.launchWebSocket(identifier: "some-id")
            app.userDefaultsRegisterDefaults(["websocketport": port])
            app.stubWebSocketReceiveMessage(identifier: "some-id", responseData: Data("Hello, world!".utf8))
        }
     
        XCTContext.runActivity(named: "Test connection") { _ in
            app.cells["executeWebSocket"].tap()
            
            wait { self.app.staticTexts["connected"].exists }
        }
        
        XCTContext.runActivity(named: "Test launch block stubbing") { _ in
            app.buttons["Ping"].tap()
            
            wait { self.app.staticTexts["Pong received"].exists }
        }
    }
}
