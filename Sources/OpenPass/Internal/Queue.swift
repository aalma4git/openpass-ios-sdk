//
//  Queue.swift
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

/// When bridging from a sync to async context using multiple `Task`s, order of execution is not guaranteed.
/// Using an `AsyncStream` we can bridge enqueued work to an async context within a single `Task`.
/// https://forums.swift.org/t/a-pitfall-when-using-didset-and-task-together-order-cant-be-guaranteed/71311/6
@available(iOS 13, tvOS 13, *)
final class Queue {
    typealias Operation = @Sendable () async -> Void
    private let continuation: AsyncStream<Operation>.Continuation
    private let task: Task<Void, Never>

    init() {
        let (stream, continuation) = AsyncStream.makeStream(of: Operation.self)

        self.continuation = continuation
        self.task = Task {
            for await operation in stream {
                await operation()
            }
        }
    }

    func enqueue(_ operation: @escaping Operation) {
        continuation.yield(operation)
    }

    deinit {
        task.cancel()
    }
}
