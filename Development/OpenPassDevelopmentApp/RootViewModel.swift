//
//  RootViewModel.swift
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

import CoreImage.CIFilterBuiltins
import Foundation
import OpenPass
import SwiftUI

@MainActor
class RootViewModel: ObservableObject {
    private let manager: OpenPassManager = .shared
    private var observeTokensTask: Task<Void, Never>?

    @Published private(set) var titleText = LocalizedStringKey("common.openpasssdk")
    @Published private(set) var openPassTokens: OpenPassTokens?
    @Published private(set) var error: Error?
    @Published var showDAF: Bool = false

    var canRefreshTokens: Bool {
        openPassTokens?.refreshToken != nil
    }

    // MARK: - Display Data Formatters
    
    var idJWTToken: String {
        if let token = openPassTokens?.idTokenJWT {
            return token
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var accessToken: String {
        if let token = openPassTokens?.accessToken {
            return token
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var tokenType: String {
        if let token = openPassTokens?.tokenType {
            return token
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var expiresAt: String {
        if let expiry = openPassTokens?.idTokenExpiry {
            return expiry.description
        }
        return NSLocalizedString("common.nil", comment: "")
    }

    var refreshToken: String {
        if let token = openPassTokens?.refreshToken {
            return token
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var email: String {
        if let email = openPassTokens?.idToken?.email {
            return email
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var givenName: String {
        if let givenName = openPassTokens?.idToken?.givenName {
            return givenName
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var familyName: String {
        if let familyName = openPassTokens?.idToken?.familyName {
            return familyName
        }
        return NSLocalizedString("common.nil", comment: "")
    }

    init() {
        openPassTokens = manager.openPassTokens
    }

    // MARK: - UX Flows

    public func startObservingTokens() {
        observeTokensTask = Task {
            for await value in manager.openPassTokensValues() {
                self.openPassTokens = value
            }
        }
    }

    public func stopObservingTokens() {
        observeTokensTask?.cancel()
        observeTokensTask = nil
    }

    public func startSignInUXFlow() {
        signOut()
        Task(priority: .userInitiated) {
            do {
                try await manager.signInFlow.beginSignIn()
            } catch {
                self.error = error
            }
        }
    }

    public func startSignInDAFFlow() {
        signOut()
        showDAF = true
    }

    // MARK: - Sign In Data Access

    public func refreshTokenFlow() {
        guard let refreshToken = manager.openPassTokens?.refreshToken else {
            // Button should be disabled
            return
        }

        Task(priority: .userInitiated) {
            do {
                let flow = manager.refreshTokenFlow
                try await _ = flow.refreshTokens(refreshToken)
            }
        }
    }

    // MARK: - Sign Out Data Access

    public func signOut() {
        _ = manager.signOut()
        self.error = nil
    }
    
}
