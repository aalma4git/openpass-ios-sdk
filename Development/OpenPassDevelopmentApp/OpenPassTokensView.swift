//
//  OpenPassTokensView.swift
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

import SwiftUI

struct OpenPassTokensView: View {

    @ObservedObject
    private var viewModel: RootViewModel

    init(_ viewModel: RootViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(LocalizedStringKey("root.title.openpassTokens"))
                .font(Font.system(size: 22, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(LocalizedStringKey("root.label.openpassTokens.idToken"))
                .font(Font.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(viewModel.idJWTToken)
                .font(Font.system(size: 16, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(LocalizedStringKey("root.label.openpassTokens.accessToken"))
                .font(Font.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(viewModel.accessToken)
                .font(Font.system(size: 16, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(LocalizedStringKey("root.label.openpassTokens.tokenType"))
                .font(Font.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(viewModel.tokenType)
                .font(Font.system(size: 16, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(LocalizedStringKey("root.label.openpassTokens.expiresIn"))
                .font(Font.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(viewModel.expiresIn)
                .font(Font.system(size: 16, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(LocalizedStringKey("root.label.openpassTokens.refreshToken"))
                .font(Font.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(viewModel.refreshToken)
                .font(Font.system(size: 16, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(LocalizedStringKey("root.label.openpassTokens.email"))
                .font(Font.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(viewModel.email)
                .font(Font.system(size: 16, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(LocalizedStringKey("root.label.openpassTokens.givenName"))
                .font(Font.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(viewModel.givenName)
                .font(Font.system(size: 16, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(LocalizedStringKey("root.label.openpassTokens.familyName"))
                .font(Font.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(viewModel.familyName)
                .font(Font.system(size: 16, weight: .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .padding([.leading, .trailing, .top], 16)
    }
}
