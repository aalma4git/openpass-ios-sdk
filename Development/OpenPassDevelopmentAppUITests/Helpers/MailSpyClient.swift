//
//  MailSlurpClient.swift
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
import OpenPass

struct Configuration: Decodable {
    var mailSpyApiKey: String
    var mailSpyEnvironment: Environment
}

struct Environment: Decodable {

    static let development = Environment(baseURL: URL(string: "https://api.dev.op-mail-testing.io")!)
    static let staging = Environment(baseURL: URL(string: "https://api.stg.op-mail-testing.io")!)
    static let production = Environment(baseURL: URL(string: "https://api.op-mail-testing.io")!)

    var baseURL: URL

    var mailDomain: String {
        // remove prefix 'api.'
        baseURL
            .host()!
            .split(separator: ".")
            .dropFirst()
            .joined(separator: ".")
    }

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer().decode(String.self)
        switch container {
        case "development":
            self = .development
        case "staging":
            self = .staging
        default:
            self = .production
        }
    }
}

struct Inbox {
    let emailAddress: String

    init(hostname: String) {
        let id = UUID().uuidString.lowercased(with: .invariant)
        emailAddress = "\(id)@\(hostname)"
    }
}

struct Email: Decodable {
    let otp: String
}

extension Locale {
    static let invariant = Locale(identifier: "en_US_POSIX")
}

@MainActor
final class MailSpyClient {
    private let apiKey: String
    private let environment: Environment

    static func withBundleConfiguration() throws -> MailSpyClient {
        guard let url = Bundle(for: MailSpyClient.self).url(forResource: "configuration", withExtension: "json") else {
            throw ConfigurationError(message: "Missing MailSpy configuration")
        }
        let configuration = try JSONDecoder().decode(Configuration.self, from: Data(contentsOf: url))
        return MailSpyClient(apiKey: configuration.mailSpyApiKey, environment: configuration.mailSpyEnvironment)
    }

    init(apiKey: String, environment: Environment) {
        self.apiKey = apiKey
        self.environment = environment
    }

    func inbox() -> Inbox {
        .init(hostname: environment.mailDomain)
    }

    func latestOTP(from inbox: Inbox) async throws -> String? {
        let email = try await withTimeout(seconds: 40) {
            try await self.pollForLatestEmail(from: inbox)
        }

        return email.otp
    }

    /// Returns an email, or throws an error if the timeout is met
    private func pollForLatestEmail(from inbox: Inbox) async throws -> Email {
        while !Task.isCancelled {
            if let email = try await latestEmail(from: inbox) {
                return email
            }
            try await Task.sleep(nanoseconds: UInt64(5 * 1_000_000_000)) // 5 seconds
        }
        throw TimedOutError()
    }

    private func latestEmail(from inbox: Inbox) async throws -> Email? {
        let endpoint = environment.baseURL
            .appending(components: "email", "search")
            .appending(queryItems: [
                .init(name: "unreadOnly", value: "true"),
                .init(name: "limit", value: "1"),
                .init(name: "sentTo", value: inbox.emailAddress)
            ])
        var request = URLRequest(url: endpoint)
        request.addValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, _) = try await URLSession(configuration: .default).data(for: request)

        return try JSONDecoder().decode([Email].self, from: data).first
    }
}

struct ConfigurationError: Error {
    var message: String
}

// https://forums.swift.org/t/running-an-async-task-with-a-timeout/49733/13
public func withTimeout<R: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> R
) async throws -> R {
    return try await withThrowingTaskGroup(of: R.self) { group in
        let deadline = Date(timeIntervalSinceNow: seconds)

        // Start actual work.
        group.addTask {
            return try await operation()
        }
        // Start timeout child task.
        group.addTask {
            let interval = deadline.timeIntervalSinceNow
            if interval > 0 {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
            try Task.checkCancellation()
            // We’ve reached the timeout.
            throw TimedOutError()
        }
        // First finished child task wins, cancel the other task.
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

struct TimedOutError: Error, Hashable {}
