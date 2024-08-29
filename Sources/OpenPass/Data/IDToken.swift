//
//  IDToken.swift
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

import Foundation

/// OIDC ID Token Data Object
///
/// [https://openid.net/specs/openid-connect-core-1_0.html#IDToken](https://openid.net/specs/openid-connect-core-1_0.html#IDToken)
@available(iOS 13.0, tvOS 16.0, *)
public struct IDToken: Hashable, Codable, Sendable {

    internal let idTokenJWT: String
    
    // MARK: - IDToken Header Data
    /// ID of the key used to sign the token
    public let keyId: String
    
    /// Type of token
    public let tokenType: String
    
    /// Signing algorithm used
    public let algorithm: String
    
    // MARK: - IDToken Payload Data
    
    /// ID Token - Issue Identifier
    public let issuerIdentifier: String

    /// ID Token - Subject Identifier
    public let subjectIdentifier: String

    /// ID Token - Audience
    public let audience: String

    /// ID Token - Expiration Time in milliseconds
    public let expirationTime: Int64

    /// ID Token - Issued At Time in milliseconds
    public let issuedTime: Int64
    
    // MARK: - OpenPass Data

    /// Email address provided by user
    public let email: String?

    /// Given name provided by user
    public let givenName: String?

    /// Family name provided by user
    public let familyName: String?
}

extension IDToken {

    /// Primary Constructor
    /// - Parameter idTokenJWT: ID Token as a JWT
    public init?(idTokenJWT: String) {
        let components = idTokenJWT.components(separatedBy: ".")
        if components.count != 3 {
            return nil
        }

        guard let header = components[0].decodeJWTComponent(),
              let payload = components[1].decodeJWTComponent() else {
            return nil
        }

        guard let keyId = header["kid"] as? String,
              let tokenType = header["typ"] as? String,
              let algorithm = header["alg"] as? String else {
            return nil
        }

        guard let issuerIdentifier = payload["iss"] as? String,
              let subjectIdentifier = payload["sub"] as? String,
              let audience = payload["aud"] as? String,
              let expirationTime = payload["exp"] as? Int64,
              let issuedTime = payload["iat"] as? Int64 else {
            return nil
        }

        // optional
        let email = payload["email"] as? String
        let givenName = payload["given_name"] as? String
        let familyName = payload["family_name"] as? String

        self.init(
            idTokenJWT: idTokenJWT,
            keyId: keyId,
            tokenType: tokenType,
            algorithm: algorithm,
            issuerIdentifier: issuerIdentifier,
            subjectIdentifier: subjectIdentifier,
            audience: audience,
            expirationTime: expirationTime,
            issuedTime: issuedTime,
            email: email,
            givenName: givenName,
            familyName: familyName
        )
    }
}
