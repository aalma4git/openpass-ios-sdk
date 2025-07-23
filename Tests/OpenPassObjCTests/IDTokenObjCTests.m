//
//  IDTokenObjCTests.m
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

@import OpenPassObjC;
@import ObjCTestHelpers;
@import XCTest;

@interface IDTokenObjCTests : XCTestCase

@end

@implementation IDTokenObjCTests

// Returns a new Object
- (IDTokenObjC *)tokenWrapper
{
    NSString *JWT = @"eyJhbGciOiJSUzI1NiIsImtpZCI6Ijc2N2I5MjI1NDQ2MTNmNGMzNWI0ZGFhNjQ2YmJjNjRhYzQ3M2Q2ZjI2ZmEzZDZhMmIzODcxMjk1MmQ5MWJhNzMiLCJ0eXAiOiJKV1QifQ.eyJzdWIiOiIxYzYzMDljOS1iZWFlLTRjM2ItOWY5Yi0zNzA3Njk5NmQ4YTYiLCJhdWQiOiIyOTM1MjkxNTk4MjM3NDIzOTg1NyIsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6ODg4OCIsImV4cCI6MTY3NDQwODA2MCwiaWF0IjoxNjcxODE2MDYwLCJlbWFpbCI6ImZvb0BiYXIuY29tIiwiZ2l2ZW5fbmFtZSI6IkpvaG4iLCJmYW1pbHlfbmFtZSI6IkRvZSJ9.kknysH8DD6rCOjhYQhW-gai72yyw-8zEW_-bQlwgztwBfiCBtKR2kXb5q3-tNQf_MQENiUaZ4O-x3PvXJPRLIoox5NuHlmdOQHVOlBfpUDgq1unAq1D5RO5YIi1jnl6IImDNZu5rzYs2Hj8mayJ8B8sZc174zilLVyHxIiKuA5EPKOUyrTsEx7D6SrId0KJ0S9TLkAv3ZpUfsxLrxoTnRU71WO88prkB2N51Z3k8-L-oyKzOk50g_otMt4EvCIQlmn5upIGZH5mKYOow1DOVv-XuVByoikXy6HKsT8zD9iC_vqlaPtJtRctPQMox7qrlee-2BXvWchwMUDVY4NzkhA";

    return [[IDTokenObjC alloc] initWithIdTokenJWT:JWT
                                             keyId:@"767b922544613f4c35b4daa646bbc64ac473d6f26fa3d6a2b38712952d91ba73"
                                         tokenType:@"JWT"
                                         algorithm:@"RS256"
                                  issuerIdentifier:@"http://localhost:8888"
                                 subjectIdentifier:@"1c6309c9-beae-4c3b-9f9b-37076996d8a6"
                                          audience:@"29352915982374239857"
                                    expirationTime:1674408060
                                        issuedTime:1671816060
                                             email:@"foo@bar.com"
                                     emailVerified:YES
                                         givenName:@"John"
                                        familyName:@"Doe"];
}

- (void)testWrapper
{
    IDTokenObjC *token = [self tokenWrapper];
    XCTAssertEqualObjects(token.keyId, @"767b922544613f4c35b4daa646bbc64ac473d6f26fa3d6a2b38712952d91ba73");
    XCTAssertEqualObjects(token.tokenType, @"JWT");
    XCTAssertEqualObjects(token.algorithm, @"RS256");
    XCTAssertEqualObjects(token.issuerIdentifier, @"http://localhost:8888");
    XCTAssertEqualObjects(token.subjectIdentifier, @"1c6309c9-beae-4c3b-9f9b-37076996d8a6");
    XCTAssertEqualObjects(token.audience, @"29352915982374239857");
    XCTAssertEqualObjects(token.expirationTime, @1674408060);
    XCTAssertEqualObjects(token.issuedTime, @1671816060);
    XCTAssertEqualObjects(token.email, @"foo@bar.com");
    XCTAssertEqualObjects(token.givenName, @"John");
    XCTAssertEqualObjects(token.familyName, @"Doe");
}

- (void)testHashableEquatable
{
    IDTokenObjC *first = [self tokenWrapper];
    XCTAssertEqualObjects(first, first);
    XCTAssertEqual(first.hash, first.hash);

    IDTokenObjC *second = [self tokenWrapper];
    XCTAssertEqualObjects(first, second);
    XCTAssertEqual(first.hash, second.hash);
}

@end
