//
//  Request.swift
//
// MIT License
//
// Copyright (c) 2024 The Trade Desk (https://www.thetradedesk.com/)
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

enum Method: String {
    case get = "GET"
    case post = "POST"
}

enum RequestBody {
    case none
    case form([URLQueryItem])
    case json(Encodable)
}

struct Request<ResponseType> {
    var method: Method
    var path: String
    var body: RequestBody

    init(
        path: String,
        method: Method = .get,
        body: RequestBody = .none
    ) {
        self.path = path
        self.method = method
        self.body = body
    }
}

// MARK: - Telemetry

extension Request where ResponseType == Void {
    static func telemetryEvent(
        _ event: TelemetryEvent
    ) -> Request {
        .init(
            path: "/v1/api/telemetry/sdk_event",
            method: .post,
            body: .json(event)
        )
    }
}
// MARK: - Tokens

extension Request where ResponseType == OpenPassTokensResponse {
    static func authorizationCode(
        clientId: String,
        code: String,
        codeVerifier: String,
        redirectUri: String
    ) -> Request {
        .init(
            path: "/v1/api/token",
            method: .post,
            body: .form([
                .init(name: "client_id", value: clientId),
                .init(name: "code_verifier", value: codeVerifier),
                .init(name: "code", value: code),
                .init(name: "grant_type", value: "authorization_code"),
                .init(name: "redirect_uri", value: redirectUri)
            ])
        )
    }

    static func refresh(
        clientId: String,
        refreshToken: String
    ) -> Request {
        .init(
            path: "/v1/api/token",
            method: .post,
            body: .form([
                .init(name: "client_id", value: clientId),
                .init(name: "grant_type", value: "refresh_token"),
                .init(name: "refresh_token", value: refreshToken)
            ])
        )
    }
}

// MARK: - Device Auth

extension Request where ResponseType == DeviceAuthorizationResponse {
    static func authorizeDevice(clientId: String) -> Request {
        .init(
            path: "/v1/api/authorize-device",
            method: .post,
            body: .form([
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "scope", value: "openid")
            ])
        )
    }
}

extension Request where ResponseType == OpenPassTokensResponse {
    static func deviceToken(
        clientId: String,
        deviceCode: String
    ) -> Request {
        .init(
            path: "/v1/api/device-token",
            method: .post,
            body: .form([
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "device_code", value: deviceCode),
                URLQueryItem(name: "grant_type", value: "urn:ietf:params:oauth:grant-type:device_code")
            ])
        )
    }
}
