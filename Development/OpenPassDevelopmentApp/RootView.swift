//
//  RootView.swift
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

import Combine
import SwiftUI

struct RootView: View {
    
    @ObservedObject
    private var viewModel = RootViewModel()
    
    var body: some View {
        VStack {
            Text(viewModel.titleText)
                .font(Font.system(size: 28, weight: .bold))
                .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            if viewModel.error != nil {
                ErrorListView(viewModel)
            } else {
                ScrollView {
                    OpenPassTokensView(viewModel)
                    Spacer()
                }
            }
            HStack(alignment: .center, spacing: 20.0) {
                Button(LocalizedStringKey("root.button.signout")) {
                    viewModel.signOut()
                }
                .padding()
                .accessibilityIdentifierIfAvailable("signOut")

                #if !os(tvOS)
                Button(LocalizedStringKey("root.button.signin")) {
                    viewModel.startSignInUXFlow()
                }
                .padding()
                .accessibilityIdentifierIfAvailable("signIn")
                #endif

                Button(LocalizedStringKey("root.button.daf")) {
                    viewModel.startSignInDAFFlow()
                }
                .padding()
                .accessibilityIdentifierIfAvailable("signInDeviceAuth")
            }

            if viewModel.canRefreshTokens {
                HStack {
                    Button(LocalizedStringKey("root.button.refresh")) {
                        viewModel.refreshTokenFlow()
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $viewModel.showDAF, content: {
            DeviceAuthorizationView(showDeviceAuthorizationView: $viewModel.showDAF)
        })
    }
}
extension View {
    func accessibilityIdentifierIfAvailable(_ identifier: String) -> some View {
        if #available(iOS 14.0, *) {
            return self.accessibilityIdentifier(identifier)
        } else {
            return self
        }
    }
}
