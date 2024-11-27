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
@testable import OpenPass
@testable import OpenPassObjC

@objc
extension IDTokenObjC {
    @objc
    public convenience init(
        idTokenJWT: String,
        keyId: String,
        tokenType: String,
        algorithm: String,
        issuerIdentifier: String,
        subjectIdentifier: String,
        audience: String,
        expirationTime: Int,
        issuedTime: Int,
        email: String? = nil,
        givenName: String? = nil,
        familyName: String? = nil
    ) {
        let token = IDToken(
            idTokenJWT: idTokenJWT,
            keyId: keyId,
            tokenType: tokenType,
            algorithm: algorithm,
            issuerIdentifier: issuerIdentifier,
            subjectIdentifier: subjectIdentifier,
            audience: audience,
            expirationTime: Int64(expirationTime),
            issuedTime: Int64(issuedTime),
            email: email,
            givenName: givenName,
            familyName: familyName
        )
        self.init(token)
    }
}
