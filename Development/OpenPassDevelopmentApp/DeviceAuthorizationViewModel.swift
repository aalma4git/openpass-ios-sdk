//
//  DeviceAuthorizationViewModel.swift
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

import CoreImage.CIFilterBuiltins
import Foundation
import OpenPass
import SwiftUI

extension DeviceAuthorizationViewModel {

    /// A interface defining the flow of state communicated by the `DeviceAuthorizationFlow`
    public enum State: Sendable {

        /// The client has been initialized but a `DeviceCode` has not been requested or received
        case initial

        /// A `DeviceCode` is loaded
        case deviceCodeAvailable(DeviceCode)

        /// The flow is complete and the associated `OpenPassManager` has obtained the set of `OpenPassTokens`.
        case complete(OpenPassTokens)

        /// The previous `DeviceCode` has expired and the flow should be restarted.
        case deviceCodeExpired

        /// An error has occurred.
        case error(Error)
    }
}

@MainActor
final class DeviceAuthorizationViewModel: ObservableObject {

    /// A QR Code representation of `deviceCode.verificationUriComplete`, if available
    @Published private(set) var verificationUriCompleteImage: UIImage?

    @Published private(set) var state: DeviceAuthorizationViewModel.State = .initial {
        didSet {
            if case .deviceCodeAvailable(let deviceCode) = state {
                verificationUriCompleteImage = deviceCode.verificationUriComplete.flatMap(UIImage.qrCode(url: ))
            } else {
                verificationUriCompleteImage = nil
            }
        }
    }

    private var signInTask: Task<Void, Never>?

    public func startSignInFlow() {
        cancelSignIn()
        state = .initial

        signInTask = Task {
            let flow = OpenPassManager.shared.deviceAuthorizationFlow

            do {
                // Request a Device Code
                let deviceCode = try await flow.fetchDeviceCode()
                state = .deviceCodeAvailable(deviceCode)

                // Poll for authorization
                let tokens = try await flow.fetchAccessToken(deviceCode: deviceCode)
                state = .complete(tokens)
            } catch OpenPassError.tokenExpired {
                state = .deviceCodeExpired
            } catch {
                state = .error(error)
            }
        }
    }

    public func cancelSignIn() {
        signInTask?.cancel()
        signInTask = nil
    }
}

extension UIImage {
    static func qrCode(url: String) -> UIImage? {
        guard let data = url.data(using: String.Encoding.ascii) else {
            return nil
        }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        guard let output = filter.outputImage?.transformed(by: transform) else {
            return nil
        }
        // The filter's outputImage isn't suitable for rendering as-is. Convert to PNG and back.
        return UIImage(ciImage: output).pngData()
            .flatMap(UIImage.init(data: ))
    }
}
