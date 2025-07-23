//
//  IDTokenTests.swift
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

import XCTest
@testable import OpenPass

@available(iOS 13.0, tvOS 16.0, *)
final class IDTokenTests: XCTestCase {
    
    // MARK: - Helper Methods
    
    private func loadJWTFromFile(_ filename: String) throws -> String {
        let data = try FixtureLoader.data(fixture: filename, withExtension: "txt")
        return String(data: data, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Invalid JWT Tests
    
    func testInvalidJWT() throws {
        let invalidJWT = try loadJWTFromFile("jwt-invalid")
        let idToken = IDToken(idTokenJWT: invalidJWT)
        
        XCTAssertNil(idToken, "Invalid JWT should return nil")
    }
    
    // MARK: - Valid JWT with Unverified User Tests
    
    func testValidJWTWithUnverifiedUser() throws {
        let jwt = try loadJWTFromFile("jwt-valid-with-unverified-user")
        let idToken = try XCTUnwrap(IDToken(idTokenJWT: jwt))
        
        // Verify that the JWT was parsed and contained all expected parameters
       XCTAssertEqual(
            idToken,
            IDToken(
                idTokenJWT: jwt,
                keyId: "TsQtpnYfcfZn5ePKEagh3cSYFqlgLouxEOmNXMQRQeU",
                tokenType: "JWT",
                algorithm: "RS256",
                issuerIdentifier: "http://localhost:8888",
                subjectIdentifier: "1c6309c9-beae-4c3b-9f9b-37076996d8a6",
                audience: "29352915982374239857",
                expirationTime: 1674408060,
                issuedTime: 1671816060,
                email: "foo@bar.com",
                emailVerified: false,
                givenName: "John",
                familyName: "Doe"
            )
        )
    }
    
    // MARK: - Valid JWT without Profile Fields Tests
    
    func testValidJWTWithoutProfileFields() throws {
        let jwt = try loadJWTFromFile("jwt-valid-without-profile")
        let idToken = try XCTUnwrap(IDToken(idTokenJWT: jwt))
        
        // Verify that the JWT was parsed and contained all expected parameters
        XCTAssertEqual(
            idToken,
            IDToken(
                idTokenJWT: jwt,
                keyId: "TsQtpnYfcfZn5ePKEagh3cSYFqlgLouxEOmNXMQRQeU",
                tokenType: "JWT",
                algorithm: "RS256",
                issuerIdentifier: "http://localhost:8888",
                subjectIdentifier: "1c6309c9-beae-4c3b-9f9b-37076996d8a6",
                audience: "29352915982374239857",
                expirationTime: 1674408060,
                issuedTime: 1671816060,
                email: "foo@bar.com",
                emailVerified: true,
                givenName: nil,
                familyName: nil
            )
        )
    }
} 