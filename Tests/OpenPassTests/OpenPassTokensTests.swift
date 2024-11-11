//
//  AuthenticationStateTests.swift
//  
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
//The above copyright notice and this permission notice shall be included in all
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

@testable import OpenPass
import XCTest

final class OpenPassTokensTests: XCTestCase {

    func testOpenPassTokensTransformations() {
        let openPassTokens = OpenPassTokens(
            idTokenJWT: "idTokenJWT",
            idTokenExpiresIn: 1,
            accessToken: "accessToken",
            tokenType: "tokenType",
            expiresIn: 86400,
            refreshToken: "refresh-token-value",
            refreshTokenExpiresIn: 2,
            issuedAt: Date()
        )
        
        guard let data = try? openPassTokens.toData() else {
            XCTFail("Unable to get data from OpenPassTokens")
            return
        }

        let openPassTokensRebuilt = OpenPassTokens.fromData(data)
        XCTAssertEqual(openPassTokens, openPassTokensRebuilt)
    }

    func testOpenpassTokensFromResponse() throws {
        let response = try FixtureLoader.decode(OpenPassTokensResponse.self, fixture: "openpasstokens-401")
        XCTAssertThrowsError(try OpenPassTokens(response)) {
            error in
            guard let error = error as? OpenPassError else {
                XCTFail("Expected an error of \(OpenPassError.self)")
                return
            }
            assertOpenPassErrorsEqual(
                error,
                .tokenData(
                    name: "invalid_client",
                    description: "Could not find client for supplied id",
                    uri: "https://auth.myopenpass.com"
                )
            )
        }
    }

    func testTokenExpiryDates() {
        let openPassTokens = OpenPassTokens(
            idTokenJWT: "idTokenJWT",
            idTokenExpiresIn: 77,
            accessToken: "accessToken",
            tokenType: "tokenType",
            expiresIn: 99,
            refreshToken: "refresh-token-value",
            refreshTokenExpiresIn: 88,
            issuedAt: Date(timeIntervalSince1970: 1000)
        )
        XCTAssertEqual(openPassTokens.idTokenExpiry, Date(timeIntervalSince1970: 1077))
        XCTAssertEqual(openPassTokens.refreshTokenExpiry, Date(timeIntervalSince1970: 1088))
        XCTAssertEqual(openPassTokens.accessTokenExpiry, Date(timeIntervalSince1970: 1099))

    }

    func testTokenExpiryDatesUnknown() {
        let openPassTokens = OpenPassTokens(
            idTokenJWT: "idTokenJWT",
            idTokenExpiresIn: nil,
            accessToken: "accessToken",
            tokenType: "tokenType",
            expiresIn: 99,
            refreshToken: "refresh-token-value",
            refreshTokenExpiresIn: nil,
            issuedAt: Date(timeIntervalSince1970: 1000)
        )
        XCTAssertNil(openPassTokens.idTokenExpiry)
        XCTAssertNil(openPassTokens.refreshTokenExpiry)
    }

    func testTokensWithoutOptionalFields() throws {
        let data = Data("""
        {
            "idTokenJWT": "idTokenJWT",
            "accessToken": "accessToken",
            "tokenType": "tokenType",
            "expiresIn": 99
        }
        """.utf8)

        let tokens = try XCTUnwrap(OpenPassTokens.fromData(data))
        XCTAssertEqual(tokens, OpenPassTokens(
            idTokenJWT: "idTokenJWT",
            idTokenExpiresIn: nil,
            accessToken: "accessToken",
            tokenType: "tokenType",
            expiresIn: 99,
            refreshToken: nil,
            refreshTokenExpiresIn: nil,
            issuedAt: nil
        ))
    }
}
