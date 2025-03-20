//
//  DeviceAuthorizationFlow.swift
//
// MIT License
//
// Copyright (c) 2023 The Trade Desk (https://www.thetradedesk.com/)
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
import OSLog

/// A client for Device Authorization, a two-step flow where an input constrained device such as a TV requests a code
/// and another device inputs this code and provides authorization.
///
/// The `DeviceCode` returned in the first step contains a code which should be displayed in a user interface.
/// The flow then supports polling to check for authorization.
///
///     Task {
///        let flow = OpenPassManager.shared.deviceAuthorizationFlow
///        do {
///            // Request a Device Code
///            let deviceCode = try await flow.fetchDeviceCode()
///
///            // Present the code and uri to the user
///
///            // Poll for authorization
///            let tokens = try await flow.fetchAccessTokenPolling(deviceCode: deviceCode)
///            // do something with tokens
///        } catch {
///            // do something with error
///        }
///    }
@MainActor
public final class DeviceAuthorizationFlow {

    // When polling the token endpoint, it's possible that the response could ask us to "slow down". 
    // For each slow down response we must add an additional 5 seconds to the original interval.
    internal var slowDownMultiplier: Int64 = 0

    // The number of additional seconds that should be added to the interval if asked to slow down (the polling).
    private static let defaultSlowDownFactor: Int64 = 5

    // MARK: - Init
    
    private let openPassClient: OpenPassClient
    private let tokenValidator: IDTokenValidation
    private let tokensObserver: ((OpenPassTokens) async -> Void)
    private let dateGenerator: DateGenerator
    private let log: OSLog
    private let clock: Clock

    internal init(
        openPassClient: OpenPassClient,
        tokenValidator: IDTokenValidation,
        isLoggingEnabled: Bool,
        dateGenerator: DateGenerator = .init { Date() },
        clock: Clock = RealClock(),
        tokensObserver: @escaping ((OpenPassTokens) async -> Void)
    ) {
        self.openPassClient = openPassClient
        self.tokenValidator = tokenValidator
        self.log = isLoggingEnabled
            ? .init(subsystem: "com.myopenpass", category: "DeviceAuthorizationFlow")
            : .disabled
        self.dateGenerator = dateGenerator
        self.clock = clock
        self.tokensObserver = tokensObserver
    }

    // MARK: - Public API
    
    /// Start the authorization flow by requesting a Device Code from the API server.
    /// The ``DeviceCode`` contains values for presentation in your user interface.
    /// A  ``DeviceCode`` is also used with the `fetchAccessToken(deviceCode:)` method to check for authorization.
    /// - Returns: A Device Code representation
    public func fetchDeviceCode() async throws -> DeviceCode {
        // Reset in case the flow is reused
        slowDownMultiplier = 0

        do {
            let authorizeDeviceCodeResponse = try await openPassClient.getDeviceCode()
            switch authorizeDeviceCodeResponse {
            case .success(let response):
                return DeviceCode(response: response, now: dateGenerator.now)
            case .failure(let error):
                throw OpenPassError.unableToGenerateDeviceCode(name: error.error, description: error.errorDescription)
            }
        } catch {
            try? await openPassClient.recordEvent(
                .init(
                    clientId: openPassClient.clientId,
                    name: "device_flow_device_code_failure",
                    message: "Failed to fetch device code",
                    eventType: .info
                )
            )
            throw error
        }
    }

    /// Fetch an access token, polling until authorized.
    /// If the token expires, `OpenPassError.tokenExpired` is thrown. In this case, a new device code should be fetched.
    /// - Note: If a network error is throw, polling will cease. You will need to check for this error and resume polling as appropriate.
    /// - Returns: OpenPassTokens
    public func fetchAccessToken(deviceCode: DeviceCode) async throws -> OpenPassTokens {
        while true {
            do {
                return try await waitAndCheckAuthorization(deviceCode)
            } catch OpenPassError.tokenSlowDown {
                // Keep polling
                continue
            } catch OpenPassError.tokenAuthorizationPending {
                // Keep polling
                continue
            } catch {
                Task<Void, Never> {
                    if case OpenPassError.tokenExpired = error {
                        try? await openPassClient.recordEvent(
                            .init(
                                clientId: openPassClient.clientId,
                                name: "device_flow_token_expired",
                                message: "Token expired",
                                eventType: .info
                            )
                        )
                    } else {
                        try? await openPassClient.recordEvent(
                            .init(
                                clientId: openPassClient.clientId,
                                name: "device_flow_token_failure",
                                message: "Failed to fetch tokens from device code",
                                eventType: .error(stackTrace: Thread.formattedCallStackSymbols)
                            )
                        )
                    }
                }
                throw error
            }
        }
    }

    internal func waitAndCheckAuthorization(_ deviceCode: DeviceCode) async throws -> OpenPassTokens {
        do {
            let interval = deviceCode.interval + (slowDownMultiplier * Self.defaultSlowDownFactor)
            try await clock.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        } catch {
            throw OpenPassError.authorizationCancelled
        }

        do {
            return try await checkAuthorization(deviceCode)
        } catch let error as OpenPassError {
            if case .tokenSlowDown = error {
                slowDownMultiplier += 1
            }
            throw error
        }
    }

    /// Fetch and verify device token
    private func checkAuthorization(_ deviceCode: DeviceCode) async throws -> OpenPassTokens {
        let response = try await openPassClient.getTokenFromDeviceCode(deviceCode: deviceCode.deviceCode)
        let openPassTokens: OpenPassTokens
        switch response {
        case .success(let response):
            do {
                openPassTokens = try OpenPassTokens(response)
            } catch {
                throw OpenPassError.unableToGenerateTokenFromDeviceCode
            }
        case .failure(let error):
            throw error.openPassError
        }

        // Verify ID Token
        guard let idToken = openPassTokens.idToken,
              try await verify(idToken) else {
            Task<Void, Never> {
                try? await openPassClient.recordEvent(
                    .init(
                        clientId: openPassClient.clientId,
                        name: "device_flow_token_verification_failure",
                        message: "Token verification failed",
                        eventType: .error(stackTrace: nil)
                    )
                )
            }
            throw OpenPassError.verificationFailedForOIDCToken
        }

        // The flow is complete, notify observer and return tokens
        await tokensObserver(openPassTokens)

        return openPassTokens
    }

    /// Verifies IDToken
    /// - Parameter idToken: ID Token To Verify
    /// - Returns: true if valid, false if invalid
    private func verify(_ idToken: IDToken) async throws -> Bool {
        do {
            let jwks = try await openPassClient.fetchJWKS()
            return try tokenValidator.validate(idToken, jwks: jwks)
        } catch {
            os_log("Error verifying tokens from flow", log: log, type: .error)
            throw error
        }
    }
}

private extension OpenPassTokensResponse.Error {
    /// https://datatracker.ietf.org/doc/html/rfc8628#section-3.5
    var openPassError: OpenPassError {
        let deviceAccessTokenError = DeviceAccessTokenError(rawValue: error)
        switch deviceAccessTokenError {
        case .authorizationPending:
            return OpenPassError.tokenAuthorizationPending(name: error, description: errorDescription)
        case .slowDown:
            return OpenPassError.tokenSlowDown(name: error, description: errorDescription)
        case .expiredToken:
            return OpenPassError.tokenExpired(name: error, description: errorDescription)
        case nil:
            return OpenPassError.tokenData(name: error, description: errorDescription, uri: errorUri)
        }
    }
}
