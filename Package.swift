// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.
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

import PackageDescription

let package = Package(
    name: "OpenPass",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "OpenPass",
            targets: ["OpenPass"]
        ),
        .library(
            name: "OpenPassObjC",
            targets: ["OpenPassObjC"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "OpenPass",
            dependencies: []
        ),
        .testTarget(
            name: "OpenPassTests",
            dependencies: ["OpenPass"],
            resources: [
                .copy("TestData")
            ]
        ),
        .target(
            name: "OpenPassObjC",
            dependencies: ["OpenPass"],
            path: "Sources/OpenPassObjC",
            publicHeadersPath: "./"
        ),
        .testTarget(
            name: "OpenPassObjCTests",
            dependencies: ["OpenPassObjC", "OpenPass", "ObjCTestHelpers"]
        ),
        .target(
            name: "ObjCTestHelpers",
            dependencies: ["OpenPass", "OpenPassObjC"],
            path: "Tests/ObjCTestHelpers"
        )
    ],
    swiftLanguageVersions: [.v5])
