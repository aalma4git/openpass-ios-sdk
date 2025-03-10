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
final class OpenPassClientTests: XCTestCase {

    func testBaseRequestParameters() async throws {
        let client = OpenPassClient(
            configuration: .init(
                clientId: "id",
                redirectHost: "host",
                isLoggingEnabled: false,
                sdkVersion: "1.0.0"
            )
        )
        XCTAssertEqual(
            client.baseRequestParameters,
            .init(
                sdkName: "openpass-ios-sdk",
                sdkVersion: "1.0.0"
            )
        )
    }

    func testBaseRequestParametersWithSdkNameSuffix() async throws {
        let client = OpenPassClient(
            configuration: .init(
                clientId: "id",
                redirectHost: "host",
                isLoggingEnabled: false,
                sdkNameSuffix: "-testSuffix",
                sdkVersion: "0.a.1"
            )
        )
        XCTAssertEqual(
            client.baseRequestParameters,
            .init(
                sdkName: "openpass-ios-sdk-testSuffix",
                sdkVersion: "0.a.1"
            )
        )
    }

    func testBaseRequestParametersWithSdkNameSuffixFromSettings() async throws {
        OpenPassSettings.shared.sdkNameSuffix = "-settings-suffix"
        let client = OpenPassClient(
            configuration: .init()
        )
        OpenPassSettings.shared.sdkNameSuffix = nil
        let sdkName = try XCTUnwrap(client.baseRequestParameters.asHeaderPairs["SDK-Name"])
        XCTAssertEqual(sdkName, "openpass-ios-sdk-settings-suffix")
    }

    func testBaseURLFromConfiguration() async throws {
        OpenPassSettings.shared.environment = .custom(url: URL(string: "https://tests.example.com/")!)
        let client = OpenPassClient(
            configuration: .init()
        )
        OpenPassSettings.shared.environment = nil
        let request = client.urlRequest(Request<Void>(path: "/test"))
        XCTAssertEqual(request.url?.absoluteString, "https://tests.example.com/test")
    }

    /// 🟩  `POST /v1/api/token` - HTTP 200
    func testGetTokenFromAuthCodeSuccess() async throws {
        try HTTPStub.shared.stubAlways(fixture: "openpasstokens-200")

        let response = try await OpenPassClient.test.getTokenFromAuthCode(
            code: "bar",
            codeVerifier: "foo",
            redirectUri: "openpass://com.myopenpass.devapp"
        )
        let now = Date()
        let token = try OpenPassTokens(response, now: now)
        let idToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6Ijc2N2I5MjI1NDQ2MTNmNGMzNWI0ZGFhNjQ2YmJjNjRhYzQ3M2Q2ZjI2ZmEzZDZhMmIzODcxMjk1MmQ5MWJhNzMiLCJ0eXAiOiJKV1QifQ.eyJzdWIiOiIxYzYzMDljOS1iZWFlLTRjM2ItOWY5Yi0zNzA3Njk5NmQ4YTYiLCJhdWQiOiIyOTM1MjkxNTk4MjM3NDIzOTg1NyIsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6ODg4OCIsImV4cCI6MTY3NDQwODA2MCwiaWF0IjoxNjcxODE2MDYwLCJlbWFpbCI6ImZvb0BiYXIuY29tIiwiZ2l2ZW5fbmFtZSI6IkpvaG4iLCJmYW1pbHlfbmFtZSI6IkRvZSJ9.kknysH8DD6rCOjhYQhW-gai72yyw-8zEW_-bQlwgztwBfiCBtKR2kXb5q3-tNQf_MQENiUaZ4O-x3PvXJPRLIoox5NuHlmdOQHVOlBfpUDgq1unAq1D5RO5YIi1jnl6IImDNZu5rzYs2Hj8mayJ8B8sZc174zilLVyHxIiKuA5EPKOUyrTsEx7D6SrId0KJ0S9TLkAv3ZpUfsxLrxoTnRU71WO88prkB2N51Z3k8-L-oyKzOk50g_otMt4EvCIQlmn5upIGZH5mKYOow1DOVv-XuVByoikXy6HKsT8zD9iC_vqlaPtJtRctPQMox7qrlee-2BXvWchwMUDVY4NzkhA"
        
        let accessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxYzYzMDljOS1iZWFlLTRjM2ItOWY5Yi0zNzA3Njk5NmQ4YTYiLCJhdWQiOiIyOTM1MjkxNTk4MjM3NDIzOTg1NyIsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6ODg4OCIsImV4cCI6MTY3MTkwMjQ2MCwiaWF0IjoxNjcxODE2MDYwLCJlbWFpbCI6ImZvb0BiYXIuY29tIiwiZ2l2ZW5fbmFtZSI6IkpvaG4iLCJmYW1pbHlfbmFtZSI6IkRvZSJ9.6E5lDRd1wvezuX4UXOWPioJsxuE_OQLGb10YTXNhfCc"
        
        XCTAssertEqual(
            token,
            OpenPassTokens(
                idToken: IDToken(
                    idTokenJWT: idToken,
                    keyId: "767b922544613f4c35b4daa646bbc64ac473d6f26fa3d6a2b38712952d91ba73",
                    tokenType: "JWT",
                    algorithm: "RS256",
                    issuerIdentifier: "http://localhost:8888",
                    subjectIdentifier: "1c6309c9-beae-4c3b-9f9b-37076996d8a6",
                    audience: "29352915982374239857",
                    expirationTime: 1674408060,
                    issuedTime: 1671816060,
                    email: "foo@bar.com",
                    givenName: "John",
                    familyName: "Doe"
                ),
                idTokenJWT: idToken,
                idTokenExpiresIn: nil,
                accessToken: accessToken,
                tokenType: "Bearer",
                expiresIn: 86400,
                refreshToken: nil,
                refreshTokenExpiresIn: nil,
                issuedAt: now
            )
        )
    }

    /// 🟥  `POST /v1/api/token` - HTTP 400
    func testGetTokenFromAuthCodeBadRequestError() async throws {
        try HTTPStub.shared.stubAlways(fixture: "openpasstokens-400", statusCode: 400)

        let response = try await OpenPassClient.test.getTokenFromAuthCode(
            code: "bar",
            codeVerifier: "foo",
            redirectUri: "openpass://com.myopenpass.devapp"
        )
        XCTAssertEqual(
            response,
            .failure(
                OpenPassTokensResponse.Error(
                    error: "invalid_client",
                    errorDescription: "Could not find client for supplied id",
                    errorUri: "https://auth.myopenpass.com"
                )
            )
        )
    }

    /// 🟥  `POST /v1/api/token` - HTTP 401
    func testGetTokenFromAuthCodeUnauthorizedUserError() async throws {
        try HTTPStub.shared.stubAlways(fixture: "openpasstokens-401", statusCode: 401)

        let response = try await OpenPassClient.test.getTokenFromAuthCode(
            code: "bar",
            codeVerifier: "foo",
            redirectUri: "openpass://com.myopenpass.devapp"
        )
        XCTAssertEqual(
            response,
            .failure(
                OpenPassTokensResponse.Error(
                    error: "invalid_client",
                    errorDescription: "Could not find client for supplied id",
                    errorUri: "https://auth.myopenpass.com"
                )
            )
        )
    }

    /// 🟥  `POST /v1/api/token` - HTTP 500
    func testGetTokenFromAuthCodeServerError() async throws {
        try HTTPStub.shared.stubAlways(fixture: "openpasstokens-500", statusCode: 500)

        let response = try await OpenPassClient.test.getTokenFromAuthCode(
            code: "bar",
            codeVerifier: "foo",
            redirectUri: "openpass://com.myopenpass.devapp"
        )
        XCTAssertEqual(
            response,
            .failure(
                OpenPassTokensResponse.Error(
                    error: "server_error",
                    errorDescription: "An unexpected error has occurred",
                    errorUri: "https://auth.myopenpass.com"
                )
            )
        )
    }
 
    /// 🟩  `POST /v1/api/authorize-device` - HTTP 200
    func testGetDeviceCode() async throws {
        try HTTPStub.shared.stub(fixtures: ["/v1/api/authorize-device" : ("authorize-device-200", 200)])

        let deviceCode = try await OpenPassClient.test.getDeviceCode()

        XCTAssertEqual(
            deviceCode,
            DeviceAuthorizationResponse.success(.init(
                deviceCode: "BssE3cSE8tGw2wVp0Ah7agAAAAAAAAAA",
                userCode: "T4UGZ6RK",
                verificationUri: "https://auth.myopenpass.com/device",
                verificationUriComplete: "https://auth.myopenpass.com/device?user_code=T4UGZ6RK",
                expiresIn: 500,
                interval: 5
            ))
        )
    }

    /// 🟥  `POST /v1/api/authorize-device` - HTTP 400
    func testDeviceCodeError() async throws {
        try HTTPStub.shared.stub(fixtures: ["/v1/api/authorize-device" : ("authorize-device-400", 400)])

        let deviceCode = try await OpenPassClient.test.getDeviceCode()

        XCTAssertEqual(
            deviceCode,
            DeviceAuthorizationResponse.failure(.init(
                error: "invalid_scope",
                errorDescription: "Invalid scope, expecting openid", 
                errorUri: nil
            ))
        )
    }

    /// 🟩  `POST /v1/api/device-token` - HTTP 200
    func testGetTokenFromDeviceCode() async throws {
        try HTTPStub.shared.stub(fixtures: ["/v1/api/device-token" : ("openpasstokens-200", 200)])

        let token = try await OpenPassClient.test.getTokenFromDeviceCode(deviceCode: "12345")
        XCTAssertEqual(
            token,
            .success(
                OpenPassTokensResponse.Success(
                    accessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxYzYzMDljOS1iZWFlLTRjM2ItOWY5Yi0zNzA3Njk5NmQ4YTYiLCJhdWQiOiIyOTM1MjkxNTk4MjM3NDIzOTg1NyIsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6ODg4OCIsImV4cCI6MTY3MTkwMjQ2MCwiaWF0IjoxNjcxODE2MDYwLCJlbWFpbCI6ImZvb0BiYXIuY29tIiwiZ2l2ZW5fbmFtZSI6IkpvaG4iLCJmYW1pbHlfbmFtZSI6IkRvZSJ9.6E5lDRd1wvezuX4UXOWPioJsxuE_OQLGb10YTXNhfCc",
                    tokenType: "Bearer",
                    expiresIn: 86400,
                    idToken: "eyJhbGciOiJSUzI1NiIsImtpZCI6Ijc2N2I5MjI1NDQ2MTNmNGMzNWI0ZGFhNjQ2YmJjNjRhYzQ3M2Q2ZjI2ZmEzZDZhMmIzODcxMjk1MmQ5MWJhNzMiLCJ0eXAiOiJKV1QifQ.eyJzdWIiOiIxYzYzMDljOS1iZWFlLTRjM2ItOWY5Yi0zNzA3Njk5NmQ4YTYiLCJhdWQiOiIyOTM1MjkxNTk4MjM3NDIzOTg1NyIsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6ODg4OCIsImV4cCI6MTY3NDQwODA2MCwiaWF0IjoxNjcxODE2MDYwLCJlbWFpbCI6ImZvb0BiYXIuY29tIiwiZ2l2ZW5fbmFtZSI6IkpvaG4iLCJmYW1pbHlfbmFtZSI6IkRvZSJ9.kknysH8DD6rCOjhYQhW-gai72yyw-8zEW_-bQlwgztwBfiCBtKR2kXb5q3-tNQf_MQENiUaZ4O-x3PvXJPRLIoox5NuHlmdOQHVOlBfpUDgq1unAq1D5RO5YIi1jnl6IImDNZu5rzYs2Hj8mayJ8B8sZc174zilLVyHxIiKuA5EPKOUyrTsEx7D6SrId0KJ0S9TLkAv3ZpUfsxLrxoTnRU71WO88prkB2N51Z3k8-L-oyKzOk50g_otMt4EvCIQlmn5upIGZH5mKYOow1DOVv-XuVByoikXy6HKsT8zD9iC_vqlaPtJtRctPQMox7qrlee-2BXvWchwMUDVY4NzkhA",
                    idTokenExpiresIn: nil,
                    refreshToken: nil,
                    refreshTokenExpiresIn: nil
                )
            )
        )
    }
    
    /// 🟥  `POST /v1/api/device-token` - HTTP 400
    func testGetTokenFromDeviceCodeError() async throws {
        try HTTPStub.shared.stub(fixtures: ["/v1/api/device-token" : ("device-token-expired-token", 400)])

        let response = try await OpenPassClient.test.getTokenFromDeviceCode(deviceCode: "12345")
        XCTAssertEqual(
            response,
            .failure(
                OpenPassTokensResponse.Error(
                    error: "expired_token",
                    errorDescription: "This authorization request has expired. Please initiate a new one.",
                    errorUri: nil
                )
            )
        )
    }
}
