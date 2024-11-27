//
//  OpenPassManager.swift
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

import AuthenticationServices
import Foundation
import Security

/// Primary app interface for integrating with OpenPass SDK.
@available(iOS 13.0, tvOS 16.0, *)
@MainActor
public final class OpenPassManager {
    
    /// Singleton access point for OpenPassManager.
    public static let shared = OpenPassManager()

    /// User data for the OpenPass user currently signed in.
    public private(set) var openPassTokens: OpenPassTokens?
    
    private let openPassClient: OpenPassClient

    /// OpenPass Server URL for Web UX and API Server
    /// Override default by setting `OpenPassBaseURL` in app's Info.plist
    private let baseURL: String

    /// OpenPass Client Identifier
    /// Set `OpenPassClientId` in app's Info.plist
    private let clientId: String

    /// OpenPass Client Redirect Uri
    private var redirectUri: String? {
        guard let redirectScheme = redirectScheme else { return nil }
        guard let redirectHost = redirectHost else { return nil }
        return redirectScheme + "://" + redirectHost
    }
    
    /// Client specific redirect scheme. This always of the form `com.myopenpass.auth.{CLIENT_ID}`.
    private var redirectScheme: String? {
        guard !clientId.isEmpty else {
            return nil
        }
        return "com.myopenpass.auth.\(clientId)"
    }

    /// Client specific redirect host
    private let redirectHost: String?

    /// The SDK name. This is being send to the API via HTTP headers to track metrics.
    private let sdkName = "openpass-ios-sdk"
    
    /// The SDK version
    public let sdkVersion = "1.1.1"
    
    /// Keys and Values that need to be included in every network request
    private let baseRequestParameters: BaseRequestParameters

    private let authenticationStateGenerator: RandomStringGenerator

    /// Internal dependency
    private let authenticationSession: AuthenticationSession

    private let tokenValidator: IDTokenValidation

    /// Internal dependency
    private let clock: Clock

    /// This initializer is internal for testing.
    /// - Parameters:
    ///   - configuration: API and request parameters
    ///   - authenticationSession: Provides an authentication session. The default is to use a web based authentication session.
    ///   - authenticationStateGenerator: Authentication state generator. Defaults to a random string.
    ///   - tokenValidator: ID Token validator
    ///   - clock: Clock implementation
    internal init(
        configuration: OpenPassConfiguration = OpenPassConfiguration(),
        authenticationSession: AuthenticationSession = WebAuthenticationSession(),
        authenticationStateGenerator: RandomStringGenerator = .init { randomString(length: 32) },
        tokenValidator: IDTokenValidation? = nil,
        clock: Clock = RealClock()
    ) {
        // These are also validated in `beginSignInUXFlow`
        assert(!configuration.clientId.isEmpty, "Missing `OpenPassClientId` in Info.plist")
        assert(!configuration.redirectHost.isEmpty, "Missing `OpenPassRedirectHost` in Info.plist")
        baseRequestParameters = BaseRequestParameters(sdkName: sdkName, sdkVersion: sdkVersion)
        self.baseURL = configuration.baseURL
        self.clientId = configuration.clientId
        self.redirectHost = configuration.redirectHost

        self.openPassClient = OpenPassClient(
            baseURL: self.baseURL,
            baseRequestParameters: baseRequestParameters,
            clientId: clientId
        )
        self.authenticationSession = authenticationSession
        self.authenticationStateGenerator = authenticationStateGenerator

        let issuerID: String
        if self.baseURL.hasSuffix("/") {
            issuerID = String(self.baseURL.dropLast(1))
        } else {
            issuerID = self.baseURL
        }
        self.tokenValidator = tokenValidator ?? IDTokenValidator(clientID: clientId, issuerID: issuerID)
        self.clock = clock
        // Check for cached signin
        self.openPassTokens = KeychainManager.main.getOpenPassTokensFromKeychain()
    }

    /// Starts the OpenID Connect (OAuth) Authentication User Interface Flow.
    /// - Returns: Authenticated ``OpenPassTokens``
    @discardableResult
    public func beginSignInUXFlow() async throws -> OpenPassTokens {
        
        guard let redirectUri = redirectUri else {
            throw OpenPassError.missingConfiguration
        }

        // Build authentication request URL
        let authorizeState = authenticationStateGenerator()
        let codeVerifier = randomString(length: 43)
        let challengeHashString = generateCodeChallengeFromVerifierCode(verifier: codeVerifier)

        var components = URLComponents(string: baseURL)
        components?.path = "/v1/api/authorize"
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: "openid"),
            URLQueryItem(name: "state", value: authorizeState),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challengeHashString)
        ]
        components?.queryItems?.append(contentsOf: baseRequestParameters.asQueryItems)
        guard let url = components?.url, let redirectScheme = redirectScheme else {
            throw OpenPassError.authorizationUrl
        }
        
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

        self.setOpenPassTokens(openPassTokens)
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

    /// Signs user out by clearing all sign-in data currently in SDK.  This includes keychain and in-memory data.
    /// - Returns: True if signed out, False if still signed in.
    public func signOut() -> Bool {
        if KeychainManager.main.deleteOpenPassTokensFromKeychain() {
            self.openPassTokens = nil
            return true
        }

        return false
    }

    /// Returns a client flow for refreshing tokens.
    /// The client will automatically updated the OpenPassManager's `openPassTokens` if it is successful in refreshing tokens.
    ///
    ///     if let refreshToken = OpenPassManager.shared.openPassTokens?.refreshToken {
    ///       let flow = OpenPassManager.shared.refreshTokenFlow
    ///       await try flow.refreshTokens(refreshToken)
    ///     }
    ///
    public var refreshTokenFlow: RefreshTokenFlow {
        RefreshTokenFlow(
            openPassClient: openPassClient,
            clientId: clientId,
            tokenValidator: tokenValidator
        ) { [weak self] tokens in
            guard let self else {
                return
            }
            self.setOpenPassTokens(tokens)
        }
    }

    public var deviceAuthorizationFlow: DeviceAuthorizationFlow {
        DeviceAuthorizationFlow(
            openPassClient: openPassClient,
            tokenValidator: tokenValidator,
            clock: clock
        ) { [weak self] tokens in
            guard let self else {
                return
            }
            self.setOpenPassTokens(tokens)
        }
    }

    /// Utility function for persisting OpenPassTokens data after its been loaded from the API Server.
    internal func setOpenPassTokens(_ openPassTokens: OpenPassTokens) {
        assert(openPassTokens.idToken != nil, "ID Token must not be nil")
        self.openPassTokens = openPassTokens
        KeychainManager.main.saveOpenPassTokensToKeychain(openPassTokens)
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
