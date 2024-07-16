//
//  OpenPassManagerTests.swift
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
import AuthenticationServices

internal typealias TestAuthenticationSession = (_ url: URL, _ callbackURLScheme: String) async throws -> URL

@available(iOS 13.0, *)
final class OpenPassManagerTests: XCTestCase {

    static let defaultAuthenticationCallbackURL = URL(string: "com.myopenpass.auth.test-client://com.openpass?state=state123&code=123456")!

    @MainActor
    /// Test helper. Runs the sign in flow with default, 'success' parameters. Override parameters to test failure scenarios.
    private func _testSignInUXFlow(
        authenticationState: String = "state123",
        authenticationSession: TestAuthenticationSession? = nil,
        overrideFixtures: [String:(String, Int)] = [:],
        tokenValidator: IDTokenValidation = IDTokenValidationStub.valid
    ) async throws -> OpenPassTokens {
        let defaultFixtures = [
            "/v1/api/token": ("openpasstokens-200", 200),
            "/.well-known/jwks": ("jwks", 200),
        ]
        // overrides in fixtures replace defaults
        let fixtures = defaultFixtures.merging(overrideFixtures) { $1 }
        try HTTPStub.shared.stub(fixtures: fixtures)

        let manager = OpenPassManager(
            clientId: "test-client",
            redirectHost: "com.openpass",
            authenticationSession: TestAuthenticationSessionProvider(authenticationSession ?? { _, _ in OpenPassManagerTests.defaultAuthenticationCallbackURL }),
            authenticationStateGenerator: .init { authenticationState },
            tokenValidator: tokenValidator
        )

        return try await manager.beginSignInUXFlow()
    }

    // MARK: - Sign In Flow

    func testSignInSuccess() async throws {
        let tokens = try await _testSignInUXFlow()
        XCTAssertNotNil(tokens, "Expected sign-in to succeed and return tokens")
    }

    func testSignInUserCancelled() async throws {
        try await assertThrowsOpenPassError(
            await self._testSignInUXFlow(
                authenticationSession: { url, callbackURLScheme in
                    throw ASWebAuthenticationSessionError(_nsError: NSError(
                        domain: ASWebAuthenticationSessionError.errorDomain,
                        code: ASWebAuthenticationSessionError.canceledLogin.rawValue
                    ))
                }
            )
        ) { error in
            XCTAssertEqual(error, .authorizationCancelled)
        }
    }

    func testSignInAuthStateMismatch() async throws {
        try await assertThrowsOpenPassError(
            await self._testSignInUXFlow(
                authenticationState: "bad state"
            )
        ) { error in
            XCTAssertEqual(error, .authorizationCallBackDataItems)
        }
    }

    func testSignInAuthError() async throws {
        try await assertThrowsOpenPassError(
            await self._testSignInUXFlow(
                authenticationSession: { _, _ in
                    URL(string: "com.myopenpass.auth.test-client://com.openpass?error=invalid&error_description=auth-was-bad")!
                }
            )
        ) { error in
            XCTAssertEqual(error, .authorizationError(code: "invalid", description: "auth-was-bad"))
        }
    }

    func testSignInInternalServerError() async throws {
        try await assertThrowsOpenPassError(
            await self._testSignInUXFlow(
                overrideFixtures: [
                    "/v1/api/token": ("openpasstokens-500", 500),
                ]
            )
        ) { error in
            XCTAssertEqual(
                error,
                .tokenData(
                    name: "server_error",
                    description: "An unexpected error has occurred",
                    uri: "https://auth.myopenpass.com"
                )
            )
        }
    }

    func testSignInBadTokenResponse() async throws {
        try await assertThrowsOpenPassError(
            await self._testSignInUXFlow(
                overrideFixtures: [
                    "/v1/api/token": ("token-bad-data", 200),
                ]
            )
        ) { error in
            XCTAssertEqual(error, .verificationFailedForOIDCToken)
        }
    }

    func testSignInInvalidToken() async throws {
        try await assertThrowsOpenPassError(
            await self._testSignInUXFlow(
                tokenValidator: IDTokenValidationStub.invalid
            )
        ) { error in
            XCTAssertEqual(error, .verificationFailedForOIDCToken)
        }
    }

    // MARK: - Refresh Flow

    @MainActor
    func testRefreshFlow() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/token": ("openpasstokens-200", 200),
            "/.well-known/jwks": ("jwks", 200),
        ])

        let manager = OpenPassManager(
            clientId: "test-client",
            redirectHost: "com.openpass",
            authenticationSession: TestAuthenticationSessionProvider({ _, _ in fatalError("unimplemented") }),
            authenticationStateGenerator: .init { fatalError("unimplemented") },
            tokenValidator: IDTokenValidationStub.valid
        )
        let flow = manager.refreshTokenFlow

        XCTAssertNil(manager.openPassTokens)
        let tokens = try await flow.refreshTokens("refresh-token")
        XCTAssertNotNil(manager.openPassTokens, "Expected a successful refresh flow to update manager openPassTokens")
        XCTAssertEqual(tokens, manager.openPassTokens)
    }

    // MARK: - Device Authorization Flow

    @MainActor
    func testDeviceAuthorizationFlow() async throws {
        try HTTPStub.shared.stub(fixtures: [
            "/v1/api/authorize-device" : ("authorize-device-200", 200),
            "/v1/api/device-token" : ("openpasstokens-200", 200),
            "/.well-known/jwks": ("jwks", 200),
        ])

        let manager = OpenPassManager(
            clientId: "test-client",
            redirectHost: "com.openpass",
            authenticationSession: TestAuthenticationSessionProvider({ _, _ in fatalError("unimplemented") }),
            authenticationStateGenerator: .init { fatalError("unimplemented") },
            tokenValidator: IDTokenValidationStub.valid,
            clock: ImmediateClock()
        )
        let flow = manager.deviceAuthorizationFlow

        XCTAssertNil(manager.openPassTokens)
        let deviceCode = try await flow.fetchDeviceCode()
        let tokens = try await flow.fetchAccessToken(deviceCode: deviceCode)
        XCTAssertNotNil(manager.openPassTokens, "Expected a successful refresh flow to update manager openPassTokens")
        XCTAssertEqual(tokens, manager.openPassTokens)
    }

    // MARK: -

    func testAuthenticationSessionURL() async throws {
        let session: TestAuthenticationSession = { url, callbackURLScheme in
            XCTAssertEqual(callbackURLScheme, "com.myopenpass.auth.test-client")

            let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
            XCTAssertEqual(components.scheme, "https")
            XCTAssertEqual(components.host, "auth.myopenpass.com")
            XCTAssertEqual(components.path, "/v1/api/authorize")

            let ignoredQueryItems: Set = ["code_challenge", "device_model", "device_platform", "device_platform_version", "sdk_version"]
            let allQueryItemNames = (components.queryItems ?? [])
                .map(\.name)
            let allQueryItemNamesSet = Set(allQueryItemNames)
            // Don't test random/platform-specific values, just check for existence
            ignoredQueryItems.forEach { name in
                XCTAssertTrue(allQueryItemNamesSet.contains(name))
            }
            let queryItems = (components.queryItems ?? [])
                .filter { !ignoredQueryItems.contains($0.name) }
                .sorted { $0.name < $1.name }
            XCTAssertEqual(queryItems, [
                .init(name: "client_id", value: "test-client"),
                .init(name: "code_challenge_method", value: "S256"),
                .init(name: "device_manufacturer", value: "Apple"),
                .init(name: "redirect_uri", value: "com.myopenpass.auth.test-client://com.openpass"),
                .init(name: "response_type", value: "code"),
                .init(name: "scope", value: "openid"),
                .init(name: "sdk_name", value: "openpass-ios-sdk"),
                .init(name: "state", value: "state123"),
            ])

            return Self.defaultAuthenticationCallbackURL
        }
        let _ = try await _testSignInUXFlow(
            authenticationSession: session,
            tokenValidator: IDTokenValidationStub.valid
        )
    }

    @MainActor
    func testGenerateCodeChallengeFromVerifierCode() {
        // Base64-URL Encoded String
        let codeVerifier = "2hrVVNjQL-5JuQTCqrdIgHTVIIFQnxEXGOTy1VNkuQM"

        // SHA256 digested and then Base64-URL Encoded String
        let codeChallenge = "rrw_o86gcCbS5BGxT-FUC-AoVjDyMXpRDiYjXUR0Kak"

        let manager = OpenPassManager(clientId: "123", redirectHost: "openpass")
        let generatedCodeChallenge = manager.generateCodeChallengeFromVerifierCode(verifier: codeVerifier)

        XCTAssertEqual(generatedCodeChallenge, codeChallenge, "Generated Code Challenge not generated correctly")
    }
}

// MARK: - Test Utils

final class TestAuthenticationSessionProvider: AuthenticationSession {

    let authenticationSession: TestAuthenticationSession

    init(_ authenticationSession: @escaping TestAuthenticationSession) {
        self.authenticationSession = authenticationSession
    }

    func authenticate(url: URL, callbackURLScheme: String) async throws -> URL {
        try await authenticationSession(url, callbackURLScheme)
    }
}


struct IDTokenValidationStub: IDTokenValidation {
    var valid: Bool

    func validate(_ token: IDToken, jwks: JWKS) throws -> Bool {
        valid
    }

    static let valid = Self(valid: true)
    static let invalid = Self(valid: false)
}

internal func assertThrowsOpenPassError<T>(
    _ expression: @escaping @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: OpenPassError) -> Void = { _ in }
) async {
    // Use `Result.get` to rethrow inside `XCTAssertThrowsError` after the asynchronous `expression` is complete.
    let result = await Task {
        try await expression()
    }.result
    XCTAssertThrowsError(try result.get(), message(), file: file, line: line, { untypedError in
        guard let error = untypedError as? OpenPassError else {
            XCTFail("Expected error of type \(OpenPassError.self)")
            return
        }
        errorHandler(error)
    })
}

/// Convenience for tests only.
extension OpenPassError: Equatable {
    public static func == (lhs: OpenPassError, rhs: OpenPassError) -> Bool {
        switch (lhs, rhs) {
        case (.missingConfiguration, .missingConfiguration):
            return true
        case (.authorizationUrl, .authorizationUrl):
            return true
        case (.authorizationCancelled, .authorizationCancelled):
            return true
        case (.authorizationCallBackDataItems, .authorizationCallBackDataItems):
            return true
        case (.tokenData(let lName, let lDescription, let lUri), .tokenData(let rName, let rDescription, let rUri)):
            return lName == rName && lDescription == rDescription && lUri == rUri
        case (.verificationFailedForOIDCToken, .verificationFailedForOIDCToken):
            return true
        case (.invalidJWKS, .invalidJWKS):
            return true
        case (.authorizationError(let lCode, let lDescription), .authorizationError(let rCode, let rDescription)):
            return lCode == rCode && lDescription == rDescription
        case (.urlGeneration, .urlGeneration):
            return true
        default:
            return false
        }
    }
}
