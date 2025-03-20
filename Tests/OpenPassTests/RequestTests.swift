//
//  RequestTests.swift
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

final class RequestTests: XCTestCase {

    private let client = OpenPassClient(
        baseURL: OpenPassConfiguration.defaultBaseURL,
        baseRequestParameters: BaseRequestParameters(
            sdkName: OpenPassConfiguration.defaultSdkName,
            sdkVersion: "1.0.0",
            devicePlatform: "iOS",
            devicePlatformVersion: "18.0",
            deviceManufacturer: "Apple",
            deviceModel: "iPhone"
        ),
        clientId: "test-client-id",
        isLoggingEnabled: false
    )

    func testAuthorizationCodeRequest() {
        let request = Request.authorizationCode(
            clientId: "client_id_5",
            code: "code-123",
            codeVerifier: "code-verifier-456",
            redirectUri: "redirect-uri-789"
        )
        assertInlineSnapshot(of: client.urlRequest(request), as: .raw(pretty: true)) {
            """
            POST https://auth.myopenpass.com/v1/api/token
            Content-Type: application/x-www-form-urlencoded
            Device-Manufacturer: Apple
            Device-Model: iPhone
            Device-Platform-Version: 18.0
            Device-Platform: iOS
            SDK-Name: openpass-ios-sdk
            SDK-Version: 1.0.0

            client_id=client_id_5&code_verifier=code-verifier-456&code=code-123&grant_type=authorization_code&redirect_uri=redirect-uri-789
            """
        }
    }

    func testAuthorizeDeviceRequest() {
        let request = Request.authorizeDevice(clientId: "client-id-7")
        assertInlineSnapshot(of: client.urlRequest(request), as: .raw(pretty: true)) {
            """
            POST https://auth.myopenpass.com/v1/api/authorize-device
            Content-Type: application/x-www-form-urlencoded
            Device-Manufacturer: Apple
            Device-Model: iPhone
            Device-Platform-Version: 18.0
            Device-Platform: iOS
            SDK-Name: openpass-ios-sdk
            SDK-Version: 1.0.0

            client_id=client-id-7&scope=openid
            """
        }
    }

    func testDeviceTokenRequest() {
        let request = Request.deviceToken(
            clientId: "client-id-0",
            deviceCode: "device-code-1"
        )
        assertInlineSnapshot(of: client.urlRequest(request), as: .raw(pretty: true)) {
            """
            POST https://auth.myopenpass.com/v1/api/device-token
            Content-Type: application/x-www-form-urlencoded
            Device-Manufacturer: Apple
            Device-Model: iPhone
            Device-Platform-Version: 18.0
            Device-Platform: iOS
            SDK-Name: openpass-ios-sdk
            SDK-Version: 1.0.0

            client_id=client-id-0&device_code=device-code-1&grant_type=urn:ietf:params:oauth:grant-type:device_code
            """
        }
    }

    func testRefreshRequest() {
        let request = Request.refresh(
            clientId: "client_id_3",
            refreshToken: "refresh-token-value"
        )
        assertInlineSnapshot(of: client.urlRequest(request), as: .raw(pretty: true)) {
            """
            POST https://auth.myopenpass.com/v1/api/token
            Content-Type: application/x-www-form-urlencoded
            Device-Manufacturer: Apple
            Device-Model: iPhone
            Device-Platform-Version: 18.0
            Device-Platform: iOS
            SDK-Name: openpass-ios-sdk
            SDK-Version: 1.0.0

            client_id=client_id_3&grant_type=refresh_token&refresh_token=refresh-token-value
            """
        }
    }

    func testEventTelemetryInfo() {
        let request = Request.telemetryEvent(
            .init(
                clientId: "client-id-13",
                name: "An event",
                message: "of telemetry",
                eventType: .info
            )
        )
        assertInlineSnapshot(of: client.urlRequest(request), as: .raw(pretty: true)) {
            """
            POST https://auth.myopenpass.com/v1/api/telemetry/sdk_event
            Content-Type: application/json
            Device-Manufacturer: Apple
            Device-Model: iPhone
            Device-Platform-Version: 18.0
            Device-Platform: iOS
            SDK-Name: openpass-ios-sdk
            SDK-Version: 1.0.0

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
        let request = Request.telemetryEvent(
            .init(
                clientId: "client-id-13",
                name: "An event",
                message: "of telemetry",
                eventType: .error(stackTrace: "something\nhappened\n")
            )
        )
        assertInlineSnapshot(of: client.urlRequest(request), as: .raw(pretty: true)) {
            #"""
            POST https://auth.myopenpass.com/v1/api/telemetry/sdk_event
            Content-Type: application/json
            Device-Manufacturer: Apple
            Device-Model: iPhone
            Device-Platform-Version: 18.0
            Device-Platform: iOS
            SDK-Name: openpass-ios-sdk
            SDK-Version: 1.0.0

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
