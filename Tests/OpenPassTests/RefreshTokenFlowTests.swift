//
//  RefreshTokenFlowTests.swift
//
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

final class RefreshTokenFlowTests: XCTestCase {

    @MainActor
    func testRefreshTokenFlowSuccess() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/token": ("openpasstokens-200", 200),
            "/.well-known/jwks": ("jwks", 200),
        ])

        let flow = RefreshTokenFlow(
            openPassClient: .test,
            clientId: "client-id",
            tokenValidator: IDTokenValidationStub.valid,
            tokensObserver: { _ in }
        )
        let tokens = try await flow.refreshTokens("refresh-token")
        XCTAssertNotNil(tokens.accessToken)
    }

    @MainActor
    func testRefreshTokenFlowError() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/token": ("openpasstokens-500", 500),
        ])

        let flow = RefreshTokenFlow(
            openPassClient: .test,
            clientId: "client-id",
            tokenValidator: IDTokenValidationStub.valid,
            tokensObserver: { _ in }
        )
        await assertThrowsOpenPassError(
            try await flow.refreshTokens("refresh-token")
        ) { error in
            assertOpenPassErrorsEqual(error, .tokenData(
                name: "server_error",
                description: "An unexpected error has occurred",
                uri: "https://auth.myopenpass.com"
            ))
        }
    }

    @MainActor
    func testRefreshTokenFlowInvalidToken() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/token": ("openpasstokens-200", 200),
            "/.well-known/jwks": ("jwks", 200),
        ])

        let flow = RefreshTokenFlow(
            openPassClient: .test,
            clientId: "client-id",
            tokenValidator: IDTokenValidationStub.invalid,
            tokensObserver: { _ in }
        )
        await assertThrowsOpenPassError(
            try await flow.refreshTokens("refresh-token")
        ) { error in
            assertOpenPassErrorsEqual(error, .verificationFailedForOIDCToken)
        }
    }
}
