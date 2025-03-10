//
//  DeviceAuthorizationFlowTests.swift
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

@testable import OpenPass
import XCTest

final class ImmediateClock: Clock {
    func sleep(nanoseconds duration: UInt64) async throws {
        // Proceed immediately
        return
    }
}

extension DeviceAuthorizationFlow {
    static func test(
        openPassClient: OpenPassClient = .test,
        tokenValidator: IDTokenValidation = IDTokenValidationStub.valid,
        dateGenerator: DateGenerator = .init({ Date(timeIntervalSince1970: 10000) }),
        clock: Clock = ImmediateClock(),
        tokensObserver: @escaping ((OpenPassTokens) async -> Void) = { _ in }
    ) -> DeviceAuthorizationFlow {
        DeviceAuthorizationFlow(
            openPassClient: openPassClient,
            tokenValidator: tokenValidator,
            isLoggingEnabled: false,
            dateGenerator: dateGenerator,
            clock: clock,
            tokensObserver: tokensObserver
        )
    }
}

final class DeviceAuthorizationFlowTests: XCTestCase {
    var flow: DeviceAuthorizationFlow!

    @MainActor
    override func setUp() {
        flow = DeviceAuthorizationFlow.test()
    }

    // MARK: - Device Code

    @MainActor
    func testDeviceCodeAvailableState() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
            "/.well-known/jwks": ("jwks", 200),
        ])

        let deviceCode = try await flow.fetchDeviceCode()
        XCTAssertEqual(
            deviceCode,
            DeviceCode(
                userCode: "T4UGZ6RK",
                verificationUri: "https://auth.myopenpass.com/device",
                verificationUriComplete: "https://auth.myopenpass.com/device?user_code=T4UGZ6RK",
                expiresAt: Date(timeIntervalSince1970: 10500),
                deviceCode: "BssE3cSE8tGw2wVp0Ah7agAAAAAAAAAA",
                interval: 5
            )
        )
    }

    @MainActor
    func testDeviceCodeErrorState() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-400", 400),
        ])

        await assertThrowsError(
            try await self.flow.fetchDeviceCode()
        )

        // Retry with success
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
            "/.well-known/jwks": ("jwks", 200),
        ])

        let deviceCode = try await flow.fetchDeviceCode()
        XCTAssertEqual(
            deviceCode,
            DeviceCode(
                userCode: "T4UGZ6RK",
                verificationUri: "https://auth.myopenpass.com/device",
                verificationUriComplete: "https://auth.myopenpass.com/device?user_code=T4UGZ6RK",
                expiresAt: Date(timeIntervalSince1970: 10500),
                deviceCode: "BssE3cSE8tGw2wVp0Ah7agAAAAAAAAAA",
                interval: 5
            )
        )
    }

    // MARK: - Access Token

    @MainActor
    func testFlowSuccess() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
            "/v1/api/device-token" : ("openpasstokens-200", 200),
            "/.well-known/jwks": ("jwks", 200),
        ])

        let deviceCode = try await flow.fetchDeviceCode()
        let tokens = try await flow.fetchAccessToken(deviceCode: deviceCode)
        XCTAssertNotNil(tokens)
    }

    @MainActor
    func testFlowSuccessAfterWait() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
        ])
        let deviceCode = try await flow.fetchDeviceCode()

        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/device-token" : ("device-token-slow-down", 200),
        ])
        let tokens = try? await flow.waitAndCheckAuthorization(deviceCode)
        XCTAssertNil(tokens)
        
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/device-token" : ("openpasstokens-200", 200),
            "/.well-known/jwks": ("jwks", 200),
        ])
        do {
            let tokens = try await flow.fetchAccessToken(deviceCode: deviceCode)
            XCTAssertNotNil(tokens)
        }
    }

    @MainActor
    func testFlowSlowDown() async throws {
        XCTAssertEqual(flow.slowDownMultiplier, 0)

        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
        ])
        let deviceCode = try await flow.fetchDeviceCode()
        XCTAssertEqual(flow.slowDownMultiplier, 0)

        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/device-token" : ("device-token-slow-down", 200),
        ])
        _ = try? await flow.waitAndCheckAuthorization(deviceCode)
        XCTAssertEqual(flow.slowDownMultiplier, 1)

        _ = try? await flow.waitAndCheckAuthorization(deviceCode)
        XCTAssertEqual(flow.slowDownMultiplier, 2)

        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/device-token" : ("openpasstokens-200", 200),
            "/.well-known/jwks": ("jwks", 200),
        ])
        _ = try? await flow.waitAndCheckAuthorization(deviceCode)
        XCTAssertEqual(flow.slowDownMultiplier, 2)

        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
        ])
        _ = try await flow.fetchDeviceCode()
        XCTAssertEqual(flow.slowDownMultiplier, 0)
    }

    @MainActor
    func testFlowErrorJWKSFetchFail() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
            "/v1/api/device-token" : ("openpasstokens-200", 200),
        ])

        let deviceCode = try await flow.fetchDeviceCode()
        await assertThrowsError(
            try await self.flow.fetchAccessToken(deviceCode: deviceCode)
        )
    }

    @MainActor
    func testFlowErrorJWKSValidationFail() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
            "/v1/api/device-token" : ("openpasstokens-200", 200),
        ])
        let flow = DeviceAuthorizationFlow.test(
            tokenValidator: IDTokenValidationStub.invalid
        )
        let deviceCode = try await flow.fetchDeviceCode()
        await assertThrowsError(
            try await self.flow.fetchAccessToken(deviceCode: deviceCode)
        )
    }

    @MainActor
    func testFlowErrorExpiredToken() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
            "/v1/api/device-token" : ("device-token-expired-token", 400),
        ])

        let deviceCode = try await flow.fetchDeviceCode()
        await assertThrowsError(
            try await self.flow.fetchAccessToken(deviceCode: deviceCode)
        )
    }

    @MainActor
    func testFlowErrorAccessDenied() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
            "/v1/api/device-token" : ("device-token-access-denied", 400),
        ])

        let deviceCode = try await flow.fetchDeviceCode()
        await assertThrowsError(
            try await self.flow.fetchAccessToken(deviceCode: deviceCode)
        )
    }

    @MainActor
    func testFlowErrorUnrecognized() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
            "/v1/api/device-token" : ("device-token-unrecognized-error", 400),
        ])

        let deviceCode = try await flow.fetchDeviceCode()
        await assertThrowsError(
            try await self.flow.fetchAccessToken(deviceCode: deviceCode)
        )
    }

    @MainActor
    func testFlowErrorFinishesPolling() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
            "/v1/api/device-token" : ("device-token-unrecognized-error", 400),
        ])

        let deviceCode = try await flow.fetchDeviceCode()
        await assertThrowsError(
            try await self.flow.fetchAccessToken(deviceCode: deviceCode)
        )
    }
}
