//
//  OpenPassClientTests.swift
//  
//
// MIT License
//
// Copyright (c) 2022 The Trade Desk (https://www.thetradedesk.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
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

@testable import OpenPass
import XCTest

@available(iOS 13.0, *)
final class OpenPassConfigurationTests: XCTestCase {

    func testBaseURL() async throws {
        // default
        do {
            let configuration = OpenPassConfiguration()
            XCTAssertEqual(configuration.baseURL, "https://auth.myopenpass.com/")
        }

        // override
        do {
            OpenPassSettings.shared.environment = .custom(url: URL(string: "https://tests.example.com/")!)
            let configuration = OpenPassConfiguration()
            OpenPassSettings.shared.environment = nil
            XCTAssertEqual(configuration.baseURL, "https://tests.example.com/")
        }

        // default
        do {
            let configuration = OpenPassConfiguration()
            XCTAssertEqual(configuration.baseURL, "https://auth.myopenpass.com/")
        }
    }

    func testClientId() async throws {
        // default
        do {
            let configuration = OpenPassConfiguration()
            XCTAssertEqual(configuration.clientId, "")
        }

        // override
        do {
            OpenPassSettings.shared.clientId = "12345"
            let configuration = OpenPassConfiguration()
            OpenPassSettings.shared.clientId = nil
            XCTAssertEqual(configuration.clientId, "12345")
        }

        // default
        do {
            let configuration = OpenPassConfiguration()
            XCTAssertEqual(configuration.clientId, "")
        }
    }

    func testRedirectHost() async throws {
        // default
        do {
            let configuration = OpenPassConfiguration()
            XCTAssertEqual(configuration.redirectHost, "")
        }

        // override
        do {
            OpenPassSettings.shared.redirectHost = "https://tests.example.com/"
            let configuration = OpenPassConfiguration()
            OpenPassSettings.shared.redirectHost = nil
            XCTAssertEqual(configuration.redirectHost, "https://tests.example.com/")
        }

        // default
        do {
            let configuration = OpenPassConfiguration()
            XCTAssertEqual(configuration.redirectHost, "")
        }
    }

    func testSdkNameSuffix() async throws {
        // default
        do {
            let configuration = OpenPassConfiguration()
            XCTAssertEqual(configuration.sdkName, "openpass-ios-sdk")
        }

        // override
        do {
            OpenPassSettings.shared.sdkNameSuffix = "-suffix"
            let configuration = OpenPassConfiguration()
            OpenPassSettings.shared.sdkNameSuffix = nil
            XCTAssertEqual(configuration.sdkName, "openpass-ios-sdk-suffix")
        }

        // default
        do {
            let configuration = OpenPassConfiguration()
            XCTAssertEqual(configuration.sdkName, "openpass-ios-sdk")
        }
    }

}
