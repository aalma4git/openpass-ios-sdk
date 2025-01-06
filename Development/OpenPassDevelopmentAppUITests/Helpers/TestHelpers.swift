//
//  TestHelpers.swift
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

import XCTest

/// Taps 'Continue' in an alert presented by the system, typically in response to opening an external auth session
@MainActor
func waitForSpringboardAlertAndContinue() {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let alert = springboard.alerts.firstMatch
    if alert.waitForExistence(timeout: 10) {
        alert.buttons["Continue"].tap()
    }
}

/// Ported to Swift from https://www.nutrient.io/blog/running-ui-tests-with-ludicrous-speed/
/// This doesn't work for external processes, i.e. another `XCUIApplication` such as Safari.
private func _wait(for condition: @escaping () -> Bool, timeout: CFTimeInterval = 30) -> Bool {
    // We add a timer dispatch source here to make sure that we wake up at least every 0.x seconds
    // in case we're waiting for a condition that does not necessarily wake up the run loop.
    let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
    timer.schedule(wallDeadline: .now(), repeating: .milliseconds(100), leeway: .milliseconds(50))
    timer.setEventHandler {
        // NOOP
    }
    timer.resume()

    var fulfilled = false
    let flags: CFOptionFlags = CFOptionFlags(CFRunLoopActivity.beforeWaiting.rawValue)
    let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, flags, true, 0) { _, _ in
        fulfilled = condition()
        if fulfilled {
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
    }
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, .defaultMode)
    CFRunLoopRunInMode(.defaultMode, timeout, false)
    CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observer, .defaultMode)
    timer.cancel()

    // If we haven't fulfilled the condition yet, test one more time before returning. This avoids
    // that we fail the test just because we somehow failed to properly poll the condition, e.g. if
    // the run loop didn't wake up.
    if !fulfilled {
        fulfilled = condition()
    }
    return fulfilled
}

struct WaitError: Error, LocalizedError {
    var message: String
    var errorDescription: String? {
        message
    }
}

extension XCUIElement {
    /// A convenience for waiting for the element's `exists` property to be true.
    @discardableResult
    func waitForExists(
        timeout: TimeInterval = webViewTimeout,
        action: (_ element: XCUIElement) -> Void = { _ in }
    ) throws -> Bool {
        try wait(for: { $0.exists }, timeout: timeout, action: action)
    }

    /// A convenience for waiting for the element's `exists`, `isHittable` and `isEnabled` properties to be true.
    @discardableResult
    func waitForExistsInteractive(
        timeout: TimeInterval = webViewTimeout,
        action: (_ element: XCUIElement) -> Void = { _ in }
    ) throws -> Bool {
        try wait(for: { $0.exists && $0.isHittable && $0.isEnabled }, timeout: timeout, action: action)
    }

    /// Wait for a condition to be fulfilled before performing an action with the element.
    /// Throws an error if the condition is not met before the timeout. This is useful for async tests, where assertions do not halt the test.
    @discardableResult
    func wait(
        for condition: @escaping (_ element: XCUIElement) -> Bool,
        timeout: TimeInterval = webViewTimeout,
        action: (_ element: XCUIElement) -> Void = { _ in }
    ) throws -> Bool {
        let fulfilled = _wait(for: { condition(self) }, timeout: timeout)
        guard fulfilled else {
            throw WaitError(message: "Condition not fulfilled for \(self.debugDescription)")
        }
        action(self)
        return true
    }
}
