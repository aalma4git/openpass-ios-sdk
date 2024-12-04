//
//  Broadcaster.swift
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

import Foundation

/// Send a value to multiple observers
@available(iOS 13, tvOS 13, *)
@MainActor
final class Broadcaster<Element: Sendable> {
    typealias Identifier = UUID
    private var continuations: [Identifier: AsyncStream<Element>.Continuation] = [:]

    func values() -> AsyncStream<Element> {
        .init { continuation in
            let id = Identifier()
            continuations[id] = continuation

            continuation.onTermination = { _ in
                Task { [weak self] in
                    await self?.remove(id)
                }
            }
        }
    }

    func remove(_ id: Identifier) {
        continuations[id] = nil
    }

    func send(_ value: Element) {
        continuations.values.forEach { $0.yield(value) }
    }

    deinit {
        continuations.values.forEach { $0.finish() }
    }
}
