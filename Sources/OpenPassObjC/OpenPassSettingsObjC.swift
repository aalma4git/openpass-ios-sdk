//
//  OpenPassSettingsObjC.swift
//
// MIT License
//
// Copyright (c) 2025 The Trade Desk (https://www.thetradedesk.com/)
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

extension OpenPassSettings {

    /// OpenPass API Environment. The default value is `nil`, which result in Production being used.
    /// Setting a value of `Environment.custom` is equivalent to providing a value for `OpenPassBaseURL` in your Info.plist,
    /// however any value in the Info.plist will override this setting.
    @objc
    public var environmentObjC: OpenPassEnvironmentObjC? {
        get {
            environment.map(OpenPassEnvironmentObjC.init)
        }
        set {
            environment = newValue?.environment
        }
    }
}

// MARK: - Equatable

extension OpenPassEnvironmentObjC {
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else { return false }
        return environment == other.environment
    }
}

// MARK: - Hashable

extension OpenPassEnvironmentObjC {
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(environment)
        return hasher.finalize()
    }
}
