//
//  OpenPassDevelopmentAppUITests.swift
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

@preconcurrency import mailslurp
import XCTest

/// Timeout for page loads.
/// Most of the sign in flow takes place in a webview, so we're required to wait for network loads etc.
let webViewTimeout: Double = 30

@MainActor
final class OpenPassDevelopmentAppUITests: XCTestCase {

    private var inbox: InboxDto?

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDown() async throws {
        if let inbox {
            do {
                print("Deleting test inbox.")
                try await MailSlurpClient.withBundleConfiguration().delete(inbox)
            } catch {
                print("Error deleting test inbox.")
            }
        }
    }

    func testMobileSignIn() async throws {
        let app = XCUIApplication()
        app.launch()

        let client = try MailSlurpClient.withBundleConfiguration()

        // Create the email inbox
        let inbox = try await client.inbox()
        self.inbox = inbox

        let devApp = DevApp(app)
        devApp.signOutButton.waitForExistence {
            $0.tap()
        }
        devApp.signInButton.waitForExistence {
            $0.tap()
        }

        // addUIInterruptionMonitor doesn't actually seem to work
        // https://forums.developer.apple.com/forums/thread/737880
        // The springboard approach also seems unreliable on some devices.
        waitForSpringboardAlertAndContinue()

        // Returns multiple matches (three) all for the same single WebView
        let signInView = SignInView(app.webViews.firstMatch)
        try await signIn(view: signInView, client: client, inbox: inbox)

        guard app.wait(for: .runningForeground, timeout: webViewTimeout) else {
            XCTFail("App did not return to foreground")
            return
        }
    }

    func testDeviceAuth() async throws {
        let app = XCUIApplication()
        app.launch()

        let client = try MailSlurpClient.withBundleConfiguration()

        // Create the email inbox
        let inbox = try await client.inbox()
        self.inbox = inbox

        let devApp = DevApp(app)
        devApp.signOutButton.waitForExistence {
            $0.tap()
        }
        devApp.signInDeviceAuthButton.waitForExistence {
            $0.tap()
        }

        // Retrieve the verification URI
        let text = devApp.verificationUriComplete
        guard text.waitForExistence(timeout: 5),
            let authURL = URL(string: text.label) else {
            XCTFail("Missing or invalid verification URI")
            return
        }

        // Open the verification URI in Safari.app
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.open(authURL)
        guard safari.wait(for: .runningForeground, timeout: 10) else {
            XCTFail("Failed to launch Safari")
            return
        }

        // Confirm that we want to sign in for the 'device'
        safari.buttons["Accept device registration and continue"].waitForExistence(timeout: webViewTimeout) {
            $0.tap()
        }

        // Proceed with sign in process
        try await signIn(view: SignInView(safari), client: client, inbox: inbox)

        // Return to this dev app
        app.activate()

        guard app.wait(for: .runningForeground, timeout: webViewTimeout) else {
            XCTFail("App did not return to foreground")
            return
        }
    }

    func signIn(view signInView: SignInView, client: MailSlurpClient, inbox: InboxDto) async throws {
        // Ensure the webView is loaded
        if !signInView.emailInput.waitForExistence(timeout: webViewTimeout) {
            // If the email address input does not exist, then it's likely that Chrome already has a previous
            // login session active. We need to click the "Use another email" to clear out the old session
            signInView.signInWithAnotherEmail.tap()
        }

        // Ensure the webView is loaded
        guard signInView.emailInput.waitForExistence(timeout: webViewTimeout) else {
            XCTFail("Missing email input field")
            return
        }

        // Now enter the email address of the MailSlurp inbox into the text input
        // On a physical device, tapping the input is required before text may be entered
        signInView.emailInput.tap()
        signInView.emailInput.typeText(inbox.emailAddress)
        // Click Continue
        signInView.emailInputContinue.tap()

        // Now wait for the email containing the OTP
        guard let code = try await client.latestOTP(from: inbox) else {
            XCTFail("Failed to parse OTP code from email")
            return
        }

        // ...and enter it into the OTP text boxes, ensuring the webView is loaded
        guard signInView.codeInput.waitForExistence(timeout: webViewTimeout) else {
            XCTFail("OTP input page failed to load")
            return
        }
        signInView.enterCode(code)
    }

}

@MainActor
final class SignInView {
    private var rootElement: XCUIElement

    init(_ rootElement: XCUIElement) {
        self.rootElement = rootElement
    }

    var continueExistingEmail: XCUIElement {
        rootElement.buttons["Continue with previously verified email address"]
    }

    var signInWithAnotherEmail: XCUIElement {
        rootElement.links["Sign In with another email"]
    }

    var emailInput: XCUIElement {
        rootElement.textFields["Email address"]
    }

    var emailInputContinue: XCUIElement {
        rootElement.buttons["Continue"]
    }

    /// OTP Code Input suitable for testing existence
    var codeInput: XCUIElement {
        codeInput(for: 5)
    }

    func enterCode(_ code: String) {
        code.enumerated().forEach { index, char in
            // On a physical device, tapping the input is required before text may be entered
            let inputField = codeInput(for: index)
            inputField.tap()
            inputField.typeText(String(char))
        }
    }

    private func codeInput(for index: Int) -> XCUIElement {
        assert(index < 6)
        let labels = [
            "first",
            "second",
            "third",
            "fourth",
            "fifth",
            "sixth"
        ]
            .map { word in
                "Enter verification code \(word) digit"
            }
        return rootElement.textFields[labels[index]]
    }
}

/// A representation of the Dev App's main screen
@MainActor
final class DevApp {
    private var app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    var signInButton: XCUIElement {
        app.buttons["signIn"]
    }

    var signOutButton: XCUIElement {
        app.buttons["signOut"]
    }

    var signInDeviceAuthButton: XCUIElement {
        app.buttons["signInDeviceAuth"]
    }

    var verificationUriComplete: XCUIElement {
        app.staticTexts["verificationUriComplete"]
    }
}
