//
//  OpenPassClient.swift
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

import CryptoKit
import Foundation
import OSLog

/// Networking layer for OpenPass API Server
@available(iOS 13.0, tvOS 16.0, *)
internal final class OpenPassClient {
    
    /// OpenPass Server URL for Web UX and API Server
    /// Override default by setting `OpenPassBaseURL` in app's Info.plist
    private let baseURL: String

    /// Keys and Values that need to be included in every network request
    let baseRequestParameters: BaseRequestParameters

    let clientId: String
    private let session = URLSession.shared
    private let log: OSLog

    convenience init(configuration: OpenPassConfiguration) {
        self.init(
            baseURL: configuration.baseURL,
            sdkName: configuration.sdkName,
            sdkVersion: configuration.sdkVersion,
            clientId: configuration.clientId,
            isLoggingEnabled: configuration.isLoggingEnabled
        )
    }

    init(
        baseURL: String,
        sdkName: String,
        sdkVersion: String = openPassSdkVersion,
        clientId: String,
        isLoggingEnabled: Bool
    ) {
        self.baseURL = baseURL
        self.baseRequestParameters = BaseRequestParameters(sdkName: sdkName, sdkVersion: sdkVersion)
        self.clientId = clientId
        self.log = isLoggingEnabled
            ? .init(subsystem: "com.myopenpass", category: "OpenPassClient")
            : .disabled
    }

    // MARK: - Tokens

    /// Network call to get an ``OpenPassTokens``
    /// `/v1/api/token`
    /// - Parameters:
    ///   - code: Authorization Code from Network call to `api/authorize`
    ///   - codeVerifier: App Generated Code to verify request
    ///   - redirectUri: The app's specific URL Scheme set in `Info.plist`
    /// - Returns: Server Generated ``OpenPassTokens``
    func getTokenFromAuthCode(
        code: String,
        codeVerifier: String,
        redirectUri: String
    ) async throws -> OpenPassTokensResponse {
        let logTag: StaticString = "Updating Tokens"
        os_log(logTag, log: log, type: .debug)
        let request = Request.authorizationCode(
            clientId: clientId,
            code: code,
            codeVerifier: codeVerifier,
            redirectUri: redirectUri
        )
        return try await execute(request, String(logTag))
    }

    /// Refresh tokens using an existing `refreshToken`
    /// - Parameters:
    ///   - refreshToken: A refresh token
    /// - Returns: Refreshed ``OpenPassTokensResponse``
    func refreshTokens(_ refreshToken: String) async throws -> OpenPassTokensResponse {
        let logTag: StaticString = "Refreshing token"
        os_log(logTag, log: log, type: .debug)
        let request = Request.refresh(
            clientId: clientId,
            refreshToken: refreshToken
        )
        return try await execute(request, String(logTag))
    }

    // MARK: - Device Authorization Flow

    /// Get Device Code from Endpoint
    /// `/v1/api/authorize-device`
    /// - Returns: ``DeviceAuthorizationResponse`` transfer object
    func getDeviceCode() async throws -> DeviceAuthorizationResponse {
        let logTag: StaticString = "Fetching device code"
        os_log(logTag, log: log, type: .debug)
        let request = Request.authorizeDevice(clientId: clientId)
        return try await execute(request, String(logTag))
    }

    /// Get Device Token from Endpoint
    /// `/v1/api/device-token`
    /// - Parameters:
    ///     - deviceCode: Device Code retrieved from `/v1/api/authorize-device`
    /// - Returns: ``OpenPassTokens`` or an error if the request was not successful.
    func getTokenFromDeviceCode(deviceCode: String) async throws -> OpenPassTokensResponse {
        let logTag: StaticString = "Fetching token from device code"
        os_log(logTag, log: log, type: .debug)
        let request = Request.deviceToken(clientId: clientId, deviceCode: deviceCode)
        return try await execute(request, String(logTag))
    }

    // MARK: - JWKS

    func fetchJWKS() async throws -> JWKS {
        try await execute(Request<JWKS>(path: "/.well-known/jwks"), "Fetching JWKS")
    }

    // MARK: - Request Execution

    internal func urlRequest<ResponseType>(
        _ request: Request<ResponseType>
    ) -> URLRequest {
        var urlComponents = URLComponents(url: URL(string: baseURL)!, resolvingAgainstBaseURL: true)!
        urlComponents.path = request.path

        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = request.method.rawValue
        if request.method == .get {
            urlComponents.queryItems = request.queryItems
        } else if request.method == .post {
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = encodedPostBody(request.queryItems)
        }

        baseRequestParameters.asHeaderPairs.forEach { field, value in
            urlRequest.addValue(value, forHTTPHeaderField: field)
        }
        return urlRequest
    }

    private func encodedPostBody(_ queryItems: [URLQueryItem]) -> Data {
        var urlComponents = URLComponents()
        urlComponents.queryItems = queryItems
        let query = urlComponents.query ?? ""
        return Data(query.utf8)
    }

    private func execute<ResponseType: Decodable>(
        _ request: Request<ResponseType>,
        _ logTag: String
    ) async throws -> ResponseType {
        let urlRequest = urlRequest(
            request
        )
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await self.data(for: urlRequest)
        } catch {
            os_log("Client request error %@", log: log, type: .error, logTag)
            throw error
        }
        if response.statusCode != 200 {
            os_log("Client request error (%d) %@", log: log, type: .error, response.statusCode, logTag)
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(ResponseType.self, from: data)
        } catch {
            os_log("Error parsing response %@", log: log, type: .error, logTag)
            throw error
        }
    }

    private func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        // `URLResponse` is always `HTTPURLResponse` for HTTP requests
        // https://developer.apple.com/documentation/foundation/urlresponse
        // swiftlint:disable:next force_cast
        return (data, response as! HTTPURLResponse)
    }
}

extension OpenPassClient {
    func authorizeUrl(
        redirectUri: String,
        codeVerifier: String,
        authorizeState: String
    ) throws -> URL {
        let challengeHashString = generateCodeChallengeFromVerifierCode(verifier: codeVerifier)

        guard var components = URLComponents(string: baseURL) else {
            throw OpenPassError.missingConfiguration
        }

        components.path = "/v1/api/authorize"
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: "openid"),
            URLQueryItem(name: "state", value: authorizeState),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challengeHashString)
        ]
        components.queryItems?.append(contentsOf: baseRequestParameters.asQueryItems)
        guard let url = components.url else {
            throw OpenPassError.authorizationUrl
        }
        return url
    }
}

private func generateCodeChallengeFromVerifierCode(verifier: String) -> String {

    let codeVerifierData = Data(verifier.utf8)
    let challengeHash = SHA256.hash(data: codeVerifierData)

    // Need to get challengeHash to Data and THEN baseURLEncode
    let bytes: [UInt8] = Array(challengeHash.makeIterator())
    let data: Data = Data(bytes)
    let base64UrlEncodedHashed = data.base64EncodedString().base64URLEscaped()

    return base64UrlEncodedHashed
}

private extension String {
    init(_ string: StaticString) {
        self = string.withUTF8Buffer {
            // swiftlint:disable:next optional_data_string_conversion
            String(decoding: $0, as: UTF8.self)
        }
    }
}
