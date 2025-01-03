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
@preconcurrency import mailslurp
import OpenPass
import SwiftSoup

struct Configuration: Decodable {
    var mailslurpApiKey: String
}

@MainActor
final class MailSlurpClient {
    private let apiKey: String

    static func withBundleConfiguration() throws -> MailSlurpClient {
        guard let url = Bundle(for: MailSlurpClient.self).url(forResource: "configuration", withExtension: "json"),
              let configuration = try? JSONDecoder().decode(Configuration.self, from: Data(contentsOf: url))
        else {
            throw ConfigurationError(message: "Missing MailSlurp API key.")
        }
        return MailSlurpClient(apiKey: configuration.mailslurpApiKey)
    }

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func inbox() async throws -> InboxDto {
        try await InboxControllerAPI
            .createInboxWithDefaultsWithRequestBuilder()
            .setApiKey(apiKey)
            .execute()
            .async()
            .body
    }

    func delete(_ inbox: InboxDto) async throws {
        _ = try await InboxControllerAPI
            .deleteInboxWithRequestBuilder(inboxId: inbox._id)
            .setApiKey(apiKey)
            .execute()
            .async()
    }

    func latestOTP(from inbox: InboxDto) async throws -> String? {
        let email = try await latestEmail(from: inbox)
        guard let body = email.body else {
            return nil
        }
        let doc = try SwiftSoup.parse(body)
        return try doc.select("#otp-code").first()?.text()
    }

    private func latestEmail(from inbox: InboxDto) async throws -> Email {
        try await WaitForControllerAPI
            .waitForLatestEmailWithRequestBuilder(
                inboxId: inbox._id,
                timeout: 40 * 1000,
                unreadOnly: true,
                before: nil,
                since: nil,
                sort: nil,
                delay: nil
            )
            .setApiKey(apiKey)
            .execute()
            .async()
            .body
    }
}

fileprivate extension RequestBuilder {
    func setApiKey(_ apiKey: String) -> RequestBuilder {
        addHeader(name: "x-api-key", value: apiKey)
    }
}

struct ConfigurationError: Error {
    var message: String
}
