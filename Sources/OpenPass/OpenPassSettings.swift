//
//  OpenPassSettings.swift
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

/// An interface for configuring `OpenPassManager` behavior.
/// These settings must be configured before calling `OpenPassManager.shared` as they are read when it is initialized.
/// Subsequent changes will be ignored.
@objc
public final class OpenPassSettings: NSObject, @unchecked Sendable {

    // A simple synchronization queue.
    // We do not expect settings values to be modified frequently, or after SDK initialization.
    private let queue = DispatchQueue(label: "OpenPassSettings.sync")

    private var _clientId: String?

    /// OpenPass client identifier. The default value is `nil`.
    /// Setting this value is equivalent to providing a value for `OpenPassClientId` in your Info.plist,
    /// however any value in the Info.plist will override this one.
    @objc
    public var clientId: String? {
        get {
            queue.sync {
                _clientId
            }
        }
        set {
            queue.sync {
                _clientId = newValue
            }
        }
    }

    private var _redirectHost: String?

    /// OpenPass sign in redirect host. The default value is `nil`.
    /// Setting this value is equivalent to providing a value for `OpenPassRedirectHost` in your Info.plist,
    /// however any value in the Info.plist will override this one.
    @objc
    public var redirectHost: String? {
        get {
            queue.sync {
                _redirectHost
            }
        }
        set {
            queue.sync {
                _redirectHost = newValue
            }
        }
    }

    private var _sdkNameSuffix: String?

    /// OpenPass SDK Name suffix. The default value is `nil`.
    @objc
    public var sdkNameSuffix: String? {
        get {
            queue.sync {
                _sdkNameSuffix
            }
        }
        set {
            queue.sync {
                _sdkNameSuffix = newValue
            }
        }
    }

    @objc
    public static let shared = OpenPassSettings()
}
