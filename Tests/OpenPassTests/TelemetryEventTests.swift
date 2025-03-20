//
//  TelemetryEventTests.swift
//
// MIT License
//
// Copyright (c) 2025 The Trade Desk (https://www.thetradedesk.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation
import InlineSnapshotTesting
@testable import OpenPass
import XCTest

final class TelemetryEventTests: XCTestCase {
    
    func testEventTelemetryInfo() {
        let event = TelemetryEvent(
            clientId: "client-id-13",
            name: "An event",
            message: "of telemetry",
            eventType: .info
        )
        assertInlineSnapshot(of: event, as: .requestJson) {
            """
            {
              "client_id" : "client-id-13",
              "event_type" : "info",
              "message" : "of telemetry",
              "name" : "An event"
            }
            """
        }
    }
    
    func testEventTelemetryError() {
        let event = TelemetryEvent(
            clientId: "client-id-13",
            name: "An event",
            message: "of telemetry",
            eventType: .error(stackTrace: nil)
        )
        assertInlineSnapshot(of: event, as: .requestJson) {
            """
            {
              "client_id" : "client-id-13",
              "event_type" : "error",
              "message" : "of telemetry",
              "name" : "An event"
            }
            """
        }
    }
    
    func testEventTelemetryErrorStackTrace() {
        let event = TelemetryEvent(
            clientId: "client-id-13",
            name: "An event",
            message: "of telemetry",
            eventType: .error(stackTrace: "something\nhappened\n")
        )
        assertInlineSnapshot(of: event, as: .requestJson) {
            #"""
            {
              "client_id" : "client-id-13",
              "event_type" : "error",
              "message" : "of telemetry",
              "name" : "An event",
              "stack_trace" : "something\nhappened\n"
            }
            """#
        }
    }
}
