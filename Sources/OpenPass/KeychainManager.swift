//
//  KeychainManager.swift
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
import Security

/// Securely manages data in the Keychain
@available(iOS 13.0, tvOS 16.0, *)
internal final class KeychainManager {
    
    /// Singleton access point for KeychainManager
    public static let main = KeychainManager()

    private let attrAccount = "openpass"
    
    private let attrService = "auth-state"
    
    private init() { }
    
    /// Load ``OpenPassTokens`` from Keychain if it exists
    /// - Returns: ``OpenPassTokens`` if it exists, nil if not
    public func getOpenPassTokensFromKeychain() -> OpenPassTokens? {
        let query = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrAccount): attrAccount,
            String(kSecAttrService): attrService,
            String(kSecReturnData): true
        ] as [String: Any] as CFDictionary
            
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
            
        if let data = result as? Data {
            return OpenPassTokens.fromData(data)
        }
        
        return nil
    }
    
    /// Save given ``OpenPassTokens`` to Keychain.  Overwrites previously saved data if exists
    /// - Parameter openPassTokens: New ``OpenPassTokens`` to save to Keychain
    /// - Returns: true if saved, false if not
    @discardableResult
    public func saveOpenPassTokensToKeychain(_ openPassTokens: OpenPassTokens) -> Bool {
        
        do {
            let data = try openPassTokens.toData()

            if let _ = getOpenPassTokensFromKeychain() {
                
                let query: CFDictionary = [
                    String(kSecClass): kSecClassGenericPassword,
                    String(kSecAttrService): attrService,
                    String(kSecAttrAccount): attrAccount
                ] as [String: Any] as CFDictionary
                
                let attributesToUpdate = [String(kSecValueData): data] as CFDictionary
                
                let result = SecItemUpdate(query, attributesToUpdate)
                return result == errSecSuccess
            } else {
                let keychainItem: [String: Any] = [
                    String(kSecClass): kSecClassGenericPassword,
                    String(kSecAttrAccount): attrAccount,
                    String(kSecAttrService): attrService,
                    String(kSecUseDataProtectionKeychain): true,
                    String(kSecValueData): data
                ]

                let result = SecItemAdd(keychainItem as CFDictionary, nil)
                return result == errSecSuccess
            }
        } catch {
            // Fall through to return false
        }

        return false
    }
    
    @discardableResult
    /// Deletes ``OpenPassTokens`` from Keychain if one existed
    /// - Returns: true if deleted, false if not
    public func deleteOpenPassTokensFromKeychain() -> Bool {
        
        let query: [String: Any] = [String(kSecClass): kSecClassGenericPassword,
                                    String(kSecAttrAccount): attrAccount,
                                    String(kSecAttrService): attrService]

        let status: OSStatus = SecItemDelete(query as CFDictionary)
#if targetEnvironment(simulator)
        /// Keychain operations sometimes (often?) fail while running unit tests in the simulator, but we expect the value in memory to be deleted.
        /// Tokens are only cleared from OpenPassManager if this operation succeeds.
        /// A future breaking change may allow us to change the existing behaviour.
        return true
#else
        return status == errSecSuccess
#endif
    }
    
}
