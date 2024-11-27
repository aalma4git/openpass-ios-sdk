//
//  OpenPassManagerObjC.swift
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

@MainActor
@objc
public final class OpenPassManagerObjC: NSObject {

    private let manager = OpenPassManager.shared

    @objc
    public static let shared = OpenPassManagerObjC()

    private override init() {
        super.init()
    }

    /// User data for the OpenPass user currently signed in.
    @objc
    public var openPassTokens: OpenPassTokensObjC? {
        manager.openPassTokens.map(OpenPassTokensObjC.init)
    }

    /// Starts the OpenID Connect (OAuth) Authentication User Interface Flow.
    @objc
    public func beginSignInUXFlow() async throws -> OpenPassTokensObjC {
        let tokens = try await manager.beginSignInUXFlow()
        return OpenPassTokensObjC(tokens)
    }

    /// Signs user out by clearing all sign-in data currently in SDK.  This includes keychain and in-memory data.
    @objc
    @discardableResult
    public func signOut() -> Bool {
        manager.signOut()
    }

    /// Returns a client flow for refreshing tokens.
    /// The client will automatically updated the OpenPassManager's `openPassTokens` if it is successful in refreshing tokens.
    ///
    ///     RefreshTokenFlowObjC *flow = OpenPassManagerObjC.shared.refreshTokenFlow;
    ///     [flow refreshTokens:refreshToken completionHandler:^(OpenPassTokensObjC * _Nullable tokens, NSError * _Nullable error) {
    ///         dispatch_async(dispatch_get_main_queue(), ^{
    ///             // Update UI
    ///         });
    ///     }];
    @objc
    public var refreshTokenFlow: RefreshTokenFlowObjC {
        RefreshTokenFlowObjC(refreshTokenFlow: manager.refreshTokenFlow)
    }

    /// Returns a client flow for authorization with an external device.
    /// The client will automatically updated the OpenPassManager's `openPassTokens` if it is successful in refreshing tokens.
    ///
    ///     DeviceAuthorizationFlowObjC *flow = [OpenPassManagerObjC.shared deviceAuthorizationFlow];
    ///     [flow fetchDeviceCodeWithCompletionHandler:^(DeviceCodeObjC * _Nullable deviceCode, NSError * _Nullable error) {
    ///         if (deviceCode) {
    ///             // Present UI with device code information
    ///             // i.e. deviceCode.userCode, deviceCode.verificationUriComplete
    ///
    ///             [flow fetchAccessTokenWithDeviceCode:deviceCode completionHandler:^(OpenPassTokensObjC * _Nullable tokens, NSError * _Nullable error) {
    ///                 dispatch_async(dispatch_get_main_queue(), ^{
    ///                     // Update UI
    ///                 });
    ///             }];
    ///         }
    ///     }];
    @objc
    public var deviceAuthorizationFlow: DeviceAuthorizationFlowObjC {
        DeviceAuthorizationFlowObjC(deviceAuthorizationFlow: manager.deviceAuthorizationFlow)
    }
}
