//
//  OpenPassManagerObjCTests.m
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

@import OpenPass;
@import OpenPassObjC;
@import ObjCTestHelpers;
@import XCTest;

@interface OpenPassEnvironmentObjCTests : XCTestCase

@end

@implementation OpenPassEnvironmentObjCTests

- (void)testSettings
{
    XCTAssertNil(OpenPassSettings.shared.environmentObjC);

    OpenPassSettings.shared.environmentObjC = [OpenPassEnvironmentObjC production];
    XCTAssertEqualObjects(OpenPassSettings.shared.environmentObjC, [OpenPassEnvironmentObjC production]);

    OpenPassSettings.shared.environmentObjC = nil;
    XCTAssertNil(OpenPassSettings.shared.environmentObjC);
}

- (void)testEquatable
{
    OpenPassEnvironmentObjC *production = [OpenPassEnvironmentObjC production];
    XCTAssertTrue([production isEqual:production]);
    XCTAssertTrue([[OpenPassEnvironmentObjC production] isEqual:[OpenPassEnvironmentObjC production]]);
    XCTAssertTrue([[OpenPassEnvironmentObjC production] isEqual:[OpenPassEnvironmentObjC customWithUrl:[NSURL URLWithString:@"https://auth.myopenpass.com/"]]]);

    OpenPassEnvironmentObjC *staging = [OpenPassEnvironmentObjC staging];
    XCTAssertTrue([staging isEqual:staging]);
    XCTAssertTrue([[OpenPassEnvironmentObjC staging] isEqual:[OpenPassEnvironmentObjC staging]]);
    XCTAssertTrue([[OpenPassEnvironmentObjC staging] isEqual:[OpenPassEnvironmentObjC customWithUrl:[NSURL URLWithString:@"https://auth.stg.myopenpass.com/"]]]);

    OpenPassEnvironmentObjC *custom = [OpenPassEnvironmentObjC customWithUrl:[NSURL URLWithString:@"https://auth.myopenpass.com/"]];
    XCTAssertTrue([custom isEqual:custom]);
    XCTAssertTrue([[OpenPassEnvironmentObjC customWithUrl:[NSURL URLWithString:@"https://auth.myopenpass.com/"]] isEqual:[OpenPassEnvironmentObjC customWithUrl:[NSURL URLWithString:@"https://auth.myopenpass.com/"]]]);

    XCTAssertFalse([[OpenPassEnvironmentObjC production] isEqual:[OpenPassEnvironmentObjC staging]]);
    XCTAssertFalse([[OpenPassEnvironmentObjC production] isEqual:[OpenPassEnvironmentObjC customWithUrl:[NSURL URLWithString:@"https://example.com/"]]]);
}

- (void)testHashable
{
    OpenPassEnvironmentObjC *production = [OpenPassEnvironmentObjC production];
    XCTAssertEqualObjects(production, production);
    XCTAssertEqual(production.hash, production.hash);

    OpenPassEnvironmentObjC *staging = [OpenPassEnvironmentObjC staging];
    XCTAssertEqualObjects(staging, staging);
    XCTAssertEqual(staging.hash, staging.hash);

    OpenPassEnvironmentObjC *custom = [OpenPassEnvironmentObjC customWithUrl:[NSURL URLWithString:@"https://example.com/"]];
    XCTAssertEqualObjects(custom, custom);
    XCTAssertEqual(custom.hash, custom.hash);
}

@end
