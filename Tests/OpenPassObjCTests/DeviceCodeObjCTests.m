//
//  DeviceCodeObjCTests.m
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

@interface DeviceCodeObjCTests : XCTestCase

@end

@implementation DeviceCodeObjCTests

// Returns a new Object
- (DeviceCodeObjC *)deviceCodeWrapper
{
    return [[DeviceCodeObjC alloc] initWithUserCode:@"user_code"
                                    verificationUri:@"http://example.com/verify"
                            verificationUriComplete:@"http://example.com/verify?code=device_code"
                                          expiresAt:[NSDate dateWithTimeIntervalSince1970: 3]
                                         deviceCode:@"device_code"
                                           interval:5];
}

- (void)testWrapper
{
    DeviceCodeObjC *deviceCode = [self deviceCodeWrapper];

    XCTAssertEqualObjects(deviceCode.expiresAt, [NSDate dateWithTimeIntervalSince1970: 3]);
    XCTAssertEqualObjects(deviceCode.userCode, @"user_code");
    XCTAssertEqualObjects(deviceCode.verificationUri, @"http://example.com/verify");
    XCTAssertEqualObjects(deviceCode.verificationUriComplete, @"http://example.com/verify?code=device_code");
}

- (void)testHashableEquatable
{
    DeviceCodeObjC *first = [self deviceCodeWrapper];
    XCTAssertEqualObjects(first, first);
    XCTAssertEqual(first.hash, first.hash);

    DeviceCodeObjC *second = [self deviceCodeWrapper];
    XCTAssertEqualObjects(first, second);
    XCTAssertEqual(first.hash, second.hash);
}

@end
