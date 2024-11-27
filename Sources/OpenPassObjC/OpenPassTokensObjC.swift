//
//  OpenPassTokensObjc.swift
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

@objc
public final class OpenPassTokensObjC: NSObject {
    var openPassTokens: OpenPassTokens

    /// ID Token constructed via `idTokenJWT`
    @objc
    public var idToken: IDTokenObjC? {
        openPassTokens.idToken.map(IDTokenObjC.init)
    }

    /// ID token as JWT
    @objc
    public var idTokenJWT: String {
        openPassTokens.idTokenJWT
    }

    /// Seconds until the ID Token expires
    @objc
    public var idTokenExpiresIn: NSNumber? {
        openPassTokens.idTokenExpiresIn.map(NSNumber.init(value: ))
    }

    /// Access Token
    @objc
    public var accessToken: String {
        openPassTokens.accessToken
    }

    /// Type of Access Token
    @objc
    public var tokenType: String {
        openPassTokens.tokenType
    }

    /// Seconds until the Access Token expires
    @objc
    public var expiresIn: Int64 {
        openPassTokens.expiresIn
    }

    /// Refresh Token
    @objc
    public var refreshToken: String? {
        openPassTokens.refreshToken
    }

    /// Seconds until the Refresh Token expires
    @objc
    public var refreshTokenExpiresIn: NSNumber? {
        openPassTokens.refreshTokenExpiresIn.map(NSNumber.init(value: ))
    }

    /// Instant when tokens were issued
    @objc
    public var issuedAt: Date? {
        openPassTokens.issuedAt
    }

    init(_ openPassTokens: OpenPassTokens) {
        self.openPassTokens = openPassTokens
    }

    @available(*, unavailable)
    public override init() {
        fatalError()
    }
}

// MARK: - Equatable

extension OpenPassTokensObjC {
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else { return false }
        return openPassTokens == other.openPassTokens
    }
}

// MARK: - Hashable

extension OpenPassTokensObjC {
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(openPassTokens)
        return hasher.finalize()
    }
}
