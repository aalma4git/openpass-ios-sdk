//
//  DeviceAuthorizationFlowObjC.swift
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
public final class DeviceAuthorizationFlowObjC: NSObject {
    private var deviceAuthorizationFlow: DeviceAuthorizationFlow

    init(deviceAuthorizationFlow: DeviceAuthorizationFlow) {
        self.deviceAuthorizationFlow = deviceAuthorizationFlow
    }

    @available(*, unavailable)
    public override init() {
        fatalError()
    }

    /// Start the authorization flow by requesting a Device Code from the API server.
    /// The ``DeviceCodeObjC`` contains values for presentation in your user interface.
    /// A  ``DeviceCodeObjC`` is also used with the `fetchAccessToken(deviceCode:)` method to check for authorization.
    /// - Returns: A Device Code representation
    @objc
    public func fetchDeviceCode() async throws -> DeviceCodeObjC {
        let deviceCode = try await deviceAuthorizationFlow.fetchDeviceCode()
        return DeviceCodeObjC(deviceCode)
    }

    /// Fetch an access token, polling until authorized.
    /// If the token expires, `OpenPassError.tokenExpired` is thrown. In this case, a new device code should be fetched.
    /// - Note: If a network error is throw, polling will cease. You will need to check for this error and resume polling as appropriate.
    /// - Returns: OpenPassTokens
    @objc
    public func fetchAccessToken(deviceCode deviceCodeWrapper: DeviceCodeObjC) async throws -> OpenPassTokensObjC {
        let tokens = try await deviceAuthorizationFlow.fetchAccessToken(deviceCode: deviceCodeWrapper.deviceCode)
        return OpenPassTokensObjC(tokens)
    }
}
