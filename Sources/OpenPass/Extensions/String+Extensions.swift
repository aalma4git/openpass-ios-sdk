//
//  String+Extensions.swift
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

import Foundation

@available(iOS 13.0, tvOS 16.0, *)
extension String {
    
    /// Converts a base64-encoded string to a base64url-encoded string.
    ///
    /// https://tools.ietf.org/html/rfc4648#page-7
    /// - Returns: Base64URL-Escaped String
    internal func base64URLEscaped() -> String {
            return replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
    }

    /// Decodes base64url-encoded string.
    ///
    /// https://tools.ietf.org/html/rfc4648#page-7
    /// - Returns: Decoded Data
    internal func decodeBase64URLSafe() -> Data? {
        let lengthMultiple = 4
        let paddingLength = lengthMultiple - count % lengthMultiple
        let padding = (paddingLength < lengthMultiple) ? String(repeating: "=", count: paddingLength) : ""
        let base64EncodedString = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            + padding
        return Data(base64Encoded: base64EncodedString)
    }
    
    /// Decode a JWT Component (header, payload, or signature)
    /// - Returns: JWT Component decoded into Dictionary
    internal func decodeJWTComponent() -> [String: Any]? {

        guard let componentData = decodeBase64URLSafe() else {
            return nil
        }
        return try? JSONSerialization.jsonObject(with: componentData, options: []) as? [String: Any]
        
    }

    internal func trimmingTrailing(_ suffix: String) -> String {
        if hasSuffix(suffix) {
            String(dropLast(suffix.count))
        } else {
            self
        }
    }

}
