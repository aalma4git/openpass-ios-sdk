//
//  OpenPassConfiguration.swift
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

let openPassSdkVersion = "1.3.0"

struct OpenPassConfiguration: Hashable, Sendable {
    static let defaultBaseURL = "https://auth.myopenpass.com/"

    /// The SDK name. This is being send to the API via HTTP headers to track metrics.
    static let defaultSdkName = "openpass-ios-sdk"

    /// - Parameters:
    ///   - baseURL: API base URL. If `nil`, the `defaultBaseURL` is used.
    ///   - clientId: Application client identifier
    ///   - redirectHost: The expected redirect host configured for your application
    ///   - sdkNameSuffix: A suffix to apply to the default SDK name within request parameters
    init(
        baseURL: String = defaultBaseURL,
        clientId: String,
        redirectHost: String,
        sdkNameSuffix: String = "",
        sdkVersion: String = openPassSdkVersion
    ) {
        self.baseURL = baseURL
        self.clientId = clientId
        self.redirectHost = redirectHost
        self.sdkName = Self.defaultSdkName.appending(sdkNameSuffix)
        self.sdkVersion = sdkVersion
    }

    /// Initializes a Configuration reading from the `Info.plist` first, and falling back to `OpenPassSettings`, if any.
    init() {
        self.init(
            baseURL: {
                if let baseURLOverride = Bundle.main.object(forInfoDictionaryKey: "OpenPassBaseURL") as? String, !baseURLOverride.isEmpty {
                    baseURLOverride
                } else if let environment = OpenPassSettings.shared.environment {
                    environment.endpoint.absoluteString
                } else {
                    Self.defaultBaseURL
                }
            }(),
            clientId: {
                if let bundleClientId = Bundle.main.object(forInfoDictionaryKey: "OpenPassClientId") as? String {
                    bundleClientId
                } else if let settingsClientId = OpenPassSettings.shared.clientId {
                    settingsClientId
                } else {
                    ""
                }
            }(),
            redirectHost: {
                if let bundleRedirectHost = Bundle.main.object(forInfoDictionaryKey: "OpenPassRedirectHost") as? String {
                    bundleRedirectHost
                } else if let settingsRedirectHost = OpenPassSettings.shared.redirectHost {
                    settingsRedirectHost
                } else {
                    ""
                }
            }(),
            sdkNameSuffix: OpenPassSettings.shared.sdkNameSuffix ?? ""
        )
    }

    var baseURL: String
    var clientId: String
    var redirectHost: String
    var sdkName: String
    var sdkVersion: String
}
