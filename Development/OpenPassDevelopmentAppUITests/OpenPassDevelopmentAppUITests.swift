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
let webViewTimeout: Double = 15

@MainActor
final class OpenPassDevelopmentAppUITests: XCTestCase {

    /// XCTFail and other assertion methods don't stop `async` UI tests.
    /// Throwing allows us to stop the test immediately and makes causes of failure clearer.
    struct UITestError: Error {
        var message: String

        init(_ message: String) {
            self.message = message
        }
    }

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
                print("Error deleting test inbox \(error).")
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
        try devApp.signOutButton.waitForExistsInteractive {
            $0.tap()
        }
        try devApp.signInButton.waitForExistsInteractive {
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
            throw UITestError("App did not return to foreground")
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
        try devApp.signOutButton.waitForExistsInteractive {
            $0.tap()
        }
        try devApp.signInDeviceAuthButton.waitForExistsInteractive {
            $0.tap()
        }

        // Retrieve the verification URI
        let text = devApp.verificationUriComplete
        guard try text.waitForExists(),
            let authURL = URL(string: text.label) else {
            throw UITestError("Missing or invalid verification URI")
        }

        // Open the verification URI in Safari.app
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.open(authURL)
        guard safari.wait(for: .runningForeground, timeout: 10) else {
            throw UITestError("Failed to launch Safari")
        }

        // Confirm that we want to sign in for the 'device'
        let acceptButton = safari.buttons["Accept device registration and continue"]
        try acceptButton.waitForExistence {
            $0.tap()
        }

        // Wait for sign in to load
        let signInView = SignInView(safari)
        do {
            try signInView.emailInputContinue.waitForExistence()
        } catch {
            print("Unable to find email input")
        }

        // Proceed with sign in process
        try await signIn(view: signInView, client: client, inbox: inbox)

        // Return to this dev app
        app.activate()

        guard app.wait(for: .runningForeground, timeout: webViewTimeout) else {
            throw UITestError("App did not return to foreground")
        }
    }

    func signIn(view signInView: SignInView, client: MailSlurpClient, inbox: InboxDto) async throws {
        // Ensure the webView is loaded and the email input exists
        // If the user has a cached session, we will eventually tap the signInWithAnotherEmail element.
        do {
            try signInView.emailInput.waitForExistence()
        } catch {
            // If the email address input does not exist, then it's likely that Chrome already has a previous
            // login session active. We need to click the "Use another email" to clear out the old session
            signInView.signInWithAnotherEmail.tap()
        }

        func enterEmailAddress() throws {
            // Ensure the email input exists
            try signInView.emailInput.waitForExistence {
                // Now enter the email address of the MailSlurp inbox into the text input
                // On a physical device, tapping the input is required before text may be entered
                $0.tap()
                $0.typeText(inbox.emailAddress)
            }
        }

        // Enter the MailSlurp email address
        try enterEmailAddress()

        // Click Continue
        try signInView.emailInputContinue.waitForExistence {
            $0.tap()
        }

        // For reasons unknown, entering text in the emailInput often fails the first time.
        // In general, the first interaction within a WebView appears to be unreliable.
        // Wait to see if an error is shown, and reattempt email address entry.
        let errorExists = signInView.emailInputError.waitForExistence(timeout: 5)
        if errorExists {
            // Attempt to enter the email address a final time...
            try enterEmailAddress()
            // ...and then tap Continue
            try signInView.emailInputContinue.waitForExistence {
                $0.tap()
            }
        } else {
            // No error is good, just log that an error was not present.
            print("No error message found.")
        }

        // Now wait for the email containing the OTP
        guard let code = try await client.latestOTP(from: inbox) else {
            throw UITestError("Failed to parse OTP code from email")
        }

        // ...and enter it into the OTP text boxes, ensuring the webView is loaded
        try signInView.codeInput.waitForExistence { _ in
            signInView.enterCode(code)
        }
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

    var emailInputError: XCUIElement {
        rootElement.staticTexts["Please enter valid email"]
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
