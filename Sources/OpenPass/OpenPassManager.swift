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
    public private(set) var openPassTokens: OpenPassTokens? {
        didSet {
            // Capture the current value in the queue operation
            queue.enqueue { [openPassTokens] in
                await self.broadcaster.send(openPassTokens)
            }
        }
    }

    private let broadcaster = Broadcaster<OpenPassTokens?>()
    private let queue = Queue()
    public func openPassTokensValues() -> AsyncStream<OpenPassTokens?> {
        broadcaster.values()
    }

    let openPassClient: OpenPassClient

    /// OpenPass Server URL for Web UX and API Server
    /// Override default by setting `OpenPassBaseURL` in app's Info.plist
    private let baseURL: String

    /// OpenPass Client Identifier
    /// Set `OpenPassClientId` in app's Info.plist
    private let clientId: String

    /// Client specific redirect host
    private let redirectHost: String

    /// The SDK name. This is being send to the API via HTTP headers to track metrics.
    private let sdkName = "openpass-ios-sdk"
    
    /// The SDK version
    public let sdkVersion = "1.2.0"
    
    /// Keys and Values that need to be included in every network request
    private let baseRequestParameters: BaseRequestParameters

    private let tokenValidator: IDTokenValidation

    /// Internal dependency
    private let clock: Clock

    /// This initializer is internal for testing.
    /// - Parameters:
    ///   - configuration: API and request parameters
    ///   - tokenValidator: ID Token validator
    ///   - clock: Clock implementation
    internal init(
        configuration: OpenPassConfiguration = OpenPassConfiguration(),
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

    /// Signs user out by clearing all sign-in data currently in SDK.  This includes keychain and in-memory data.
    /// - Returns: True if signed out, False if still signed in.
    public func signOut() -> Bool {
        if KeychainManager.main.deleteOpenPassTokensFromKeychain() {
            self.openPassTokens = nil
            return true
        }

        return false
    }

    /// Starts the OpenID Connect (OAuth) Authentication User Interface Flow.
    /// - Returns: Authenticated ``OpenPassTokens``
    @discardableResult
    @available(
        *,
         deprecated,
         renamed: "signInFlow.beginSignIn",
         message: "Please create an explicit flow instance using the `signInFlow` and call its `beginSignIn()` method."
    )
    public func beginSignInUXFlow() async throws -> OpenPassTokens {
        return try await signInFlow.beginSignIn()
    }

    /// Returns an OpenID Connect (OAuth) Authentication User Interface Flow.
    /// The client will automatically updated the OpenPassManager's `openPassTokens` if the flow completes successfully.
    ///
    ///     let flow = OpenPassManager.shared.signInFlow
    ///     await try flow.beginSignIn()
    ///
    public var signInFlow: SignInFlow {
        SignInFlow(
            openPassClient: openPassClient,
            tokenValidator: tokenValidator,
            redirectHost: redirectHost
        ) { [weak self] tokens in
            guard let self else {
                return
            }
            self.setOpenPassTokens(tokens)
        }
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

    /// Returns a client flow for authorization with an external device.
    /// The client will automatically updated the OpenPassManager's `openPassTokens` if it is successful in refreshing tokens.
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
