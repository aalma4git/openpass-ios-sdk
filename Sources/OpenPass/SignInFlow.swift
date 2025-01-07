//
//  SignInFlow.swift
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

import AuthenticationServices
import CryptoKit
import Foundation

@MainActor
public final class SignInFlow {
    private let openPassClient: OpenPassClient
    private let tokenValidator: IDTokenValidation
    private let tokensObserver: ((OpenPassTokens) async -> Void)

    private let authenticationStateGenerator: RandomStringGenerator

    private let authenticationSession: AuthenticationSession

    /// OpenPass Client Redirect Uri
    private var redirectUri: String {
        redirectScheme + "://" + redirectHost
    }

    /// Client specific redirect scheme. This always of the form `com.myopenpass.auth.{CLIENT_ID}`.
    private var redirectScheme: String {
        "com.myopenpass.auth.\(openPassClient.clientId)"
    }

    /// Client specific redirect host
    private let redirectHost: String

    init(
        openPassClient: OpenPassClient,
        tokenValidator: IDTokenValidation,
        authenticationSession: AuthenticationSession = WebAuthenticationSession(),
        authenticationStateGenerator: RandomStringGenerator = .init { randomString(length: 32) },
        redirectHost: String,
        tokensObserver: @escaping ((OpenPassTokens) async -> Void)
    ) {
        self.openPassClient = openPassClient
        self.tokenValidator = tokenValidator
        self.authenticationSession = authenticationSession
        self.authenticationStateGenerator = authenticationStateGenerator
        self.redirectHost = redirectHost
        self.tokensObserver = tokensObserver
    }

    /// Starts the OpenID Connect (OAuth) Authentication User Interface Flow.
    /// - Returns: Authenticated ``OpenPassTokens``
    @discardableResult
    public func beginSignIn() async throws -> OpenPassTokens {
        let authorizeState = authenticationStateGenerator()
        let codeVerifier = randomString(length: 43)
        let url = try openPassClient.authorizeUrl(
            redirectUri: redirectUri,
            codeVerifier: codeVerifier,
            authorizeState: authorizeState
        )

        // Authenticate and validate callback
        let (code, state) = try await authenticate(url: url, callbackURLScheme: redirectScheme)
        guard authorizeState == state else {
            throw OpenPassError.authorizationCallBackDataItems
        }

        // Exchange authentication code for tokens
        let tokenResponse = try await openPassClient.getTokenFromAuthCode(
            code: code,
            codeVerifier: codeVerifier,
            redirectUri: redirectUri
        )
        let openPassTokens = try OpenPassTokens(tokenResponse)

        // Validate ID Token
        guard let idToken = openPassTokens.idToken,
              try await verify(idToken) else {
            throw OpenPassError.verificationFailedForOIDCToken
        }

        await tokensObserver(openPassTokens)
        return openPassTokens
    }

    /// Present the authentication flow, returning a code and client state if successful
    private func authenticate(
        url: URL,
        callbackURLScheme: String
    ) async throws -> (code: String, state: String) {
        let callbackURL: URL
        do {
            callbackURL = try await authenticationSession.authenticate(url: url, callbackURLScheme: callbackURLScheme)
        } catch {
            if let authError = error as? ASWebAuthenticationSessionError, authError.code == .canceledLogin {
                throw OpenPassError.authorizationCancelled
            } else {
                throw error
            }
        }

        guard let queryItems = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true)?.queryItems,
                !queryItems.isEmpty else {
            throw OpenPassError.authorizationCallBackDataItems
        }
        let queryItemsMap = queryItems.reduce(into: [:]) { $0[$1.name] = $1.value }

        if let error = queryItemsMap["error"],
           let errorDescription = queryItemsMap["error_description"] {
            throw OpenPassError.authorizationError(code: error, description: errorDescription)
        }

        guard let code = queryItemsMap["code"],
           let state = queryItemsMap["state"],
           !code.isEmpty,
           !state.isEmpty else {
            throw OpenPassError.authorizationCallBackDataItems
        }
        return (code: code, state: state)
    }

    /// Verifies IDToken
    /// - Parameter idToken: ID Token To Verify
    /// - Returns: true if valid, false if invalid
    private func verify(_ idToken: IDToken) async throws -> Bool {
        let jwks = try await openPassClient.fetchJWKS()
        return try tokenValidator.validate(idToken, jwks: jwks)
    }
}

internal protocol AuthenticationSession {
    func authenticate(url: URL, callbackURLScheme: String) async throws -> URL
}

/// Authenticate using `ASWebAuthenticationSession`.
internal final class WebAuthenticationSession: AuthenticationSession {
    private var session: ASWebAuthenticationSession?

    @MainActor
    func authenticate(url: URL, callbackURLScheme: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { callbackURL, error in
                defer {
                    self.session = nil
                }
                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: OpenPassError.authorizationCallBackDataItems)
                }
            }
            self.session = session
#if os(iOS)
            session.presentationContextProvider = Self.authenticationContextProvider
#endif
            session.start()
        }
    }

#if os(iOS)
    private static let authenticationContextProvider: ASWebAuthenticationPresentationContextProviding = {
        AuthenticationPresentationContextProvider()
    }()
#endif
}

#if os(iOS)
@available(iOS 13.0, *)
// swiftlint:disable:next type_name
private final class AuthenticationPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    /// Apple provided API for telling the delegate from which window it should present content to the user.
    /// - Parameter session: Current session being used to perform authentication
    /// - Returns: `ASPresentationAnchor` for the system to use to display the `ASWebAuthenticationSession`
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
#endif

/// Creates a pseudo-random string containing basic characters using `Array.randomElement()`.
/// - Parameter length: Desired string length.
/// - Returns: Random string.
private func randomString(length: Int) -> String {
    var buffer = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
    return Data(buffer).base64URLEncodedString()
}

internal struct RandomStringGenerator {
    private var generate: () -> String

    init(_ generate: @escaping () -> String) {
        self.generate = generate
    }

    var randomString: String {
        get {
            generate()
        }
        set {
            generate = { newValue }
        }
    }

    func callAsFunction() -> String {
        randomString
    }
}
