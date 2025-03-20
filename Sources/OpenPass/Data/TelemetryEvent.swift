//
//  TelemetryEvent.swift
//
// MIT License
//
// Copyright (c) 2025 The Trade Desk (https://www.thetradedesk.com/)
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

private let stackTraceMaxSize = 10_000

struct TelemetryEvent: Encodable {
    var clientId: String
    var name: String
    var message: String
    var eventType: EventType

    enum EventType {
        case info
        case error(stackTrace: String?)
    }

    enum CodingKeys: String, CodingKey {
        case clientId
        case name
        case message
        case eventType
        case stackTrace
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(name, forKey: .name)
        try container.encode(message, forKey: .message)
        switch eventType {
        case .info:
            try container.encode("info", forKey: .eventType)
        case .error(let stackTrace):
            try container.encode("error", forKey: .eventType)
            if let stackTrace {
                try container.encode(String(stackTrace.prefix(stackTraceMaxSize)), forKey: .stackTrace)
            }
        }
    }
}

extension Thread {
    static var formattedCallStackSymbols: String {
        callStackSymbols.joined(separator: "\n")
    }
}
