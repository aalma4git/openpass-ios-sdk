//
//  DeviceAuthorizationView.swift
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

import OpenPass
import SwiftUI

struct DeviceAuthorizationView: View {
    
    @StateObject
    private var viewModel = DeviceAuthorizationViewModel()

    @Binding var showDeviceAuthorizationView: Bool

    init(showDeviceAuthorizationView: Binding<Bool>) {
        self._showDeviceAuthorizationView = showDeviceAuthorizationView
    }

    var body: some View {
        VStack(spacing: 16.0) {
            switch viewModel.state {
            case .initial:
                Text("daf.label.loading")
            case .deviceCodeAvailable(let deviceCode):
                LabelItem("daf.label.usercode", value: deviceCode.userCode)
                LabelItem("daf.label.verificationuri", value: deviceCode.verificationUri)
                LabelItem(
                    "daf.label.verficationuricomplete",
                    value: deviceCode.verificationUriComplete ?? "",
                    accessibilityIdentifier: "verificationUriComplete"
                )

                if let verificationUriCompleteImage = viewModel.verificationUriCompleteImage {
                    Image(uiImage: verificationUriCompleteImage)
                        .resizable()
                        .frame(width: 200, height: 200)
                }
                Button("daf.label.cancel") {
                    viewModel.cancelSignIn()
                }
            case .deviceCodeExpired:
                Text("daf.label.expired")
                Button("daf.label.dismiss") {
                    showDeviceAuthorizationView = false
                }
            case .error(let error):
                switch error {
                case OpenPassError.authorizationCancelled:
                    Text("daf.label.user_cancelled")
                default:
                    Text("Error: \(error.localizedDescription)")
                }
                Button("daf.label.dismiss") {
                    showDeviceAuthorizationView = false
                }
            case .complete:
                Text("daf.label.complete")
                Button("daf.label.dismiss") {
                    showDeviceAuthorizationView = false
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 16.0)
        .onAppear(perform: {
            viewModel.startSignInFlow()
        })
    }
}

private struct LabelItem: View {
    var label: LocalizedStringKey
    var value: String
    var accessibilityIdentifier: String

    init(_ label: LocalizedStringKey, value: String, accessibilityIdentifier: String = "") {
        self.label = label
        self.value = value
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    var body: some View {
        Text(label)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
        Text(value)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifierIfAvailable(accessibilityIdentifier)
    }
}
