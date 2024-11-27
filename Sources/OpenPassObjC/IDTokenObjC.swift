//
//  IDTokenObjC.swift
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

import Foundation
import OpenPass

// IDToken
public final class IDTokenObjC: NSObject {
    var idToken: IDToken

    // MARK: - IDToken Header Data
    /// ID of the key used to sign the token
    @objc
    public var keyId: String {
        idToken.keyId
    }

    /// Type of token
    @objc
    public var tokenType: String {
        idToken.tokenType
    }

    /// Signing algorithm used
    @objc
    public var algorithm: String {
        idToken.algorithm
    }

    // MARK: - IDToken Payload Data

    /// ID Token - Issue Identifier
    @objc
    public var issuerIdentifier: String {
        idToken.issuerIdentifier
    }

    /// ID Token - Subject Identifier
    @objc
    public var subjectIdentifier: String {
        idToken.subjectIdentifier
    }

    /// ID Token - Audience
    @objc
    public var audience: String {
        idToken.audience
    }

    /// ID Token - Expiration Time in milliseconds
    @objc
    public var expirationTime: NSNumber {
        NSNumber(value: idToken.expirationTime)
    }

    /// ID Token - Issued At Time in milliseconds
    @objc
    public var issuedTime: NSNumber {
        NSNumber(value: idToken.issuedTime)
    }

    // MARK: - OpenPass Data

    /// Email address provided by user
    @objc
    public var email: String? {
        idToken.email
    }

    /// Given name provided by user
    @objc
    public var givenName: String? {
        idToken.givenName
    }

    /// Family name provided by user
    @objc
    public var familyName: String? {
        idToken.familyName
    }

    init(_ idToken: IDToken) {
        self.idToken = idToken
    }
    
    @available(*, unavailable)
    public override init() {
        fatalError()
    }
}

// MARK: - Equatable

extension IDTokenObjC {
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else { return false }
        return idToken == other.idToken
    }
}

// MARK: - Hashable

extension IDTokenObjC {
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(idToken)
        return hasher.finalize()
    }
}
