//
//  WSHandlerTests.swift
//  FlyingFox
//
//  Created by Simon Whitty on 20/03/2022.
//  Copyright © 2022 Simon Whitty. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/swhitty/FlyingFox
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

@testable import FlyingFox
import Foundation
import XCTest

final class WSHandlerTests: XCTestCase {

    func testFrames_CreateExpectedMessages() {
        let handler = WSDefaultHandler.make()

        XCTAssertEqual(
            try handler.makeMessage(for: .make(fin: true, opcode: .text, payload: "Hello".data(using: .utf8)!)),
            .text("Hello")
        )
        XCTAssertThrowsError(
            try handler.makeMessage(for: .make(fin: true, opcode: .text, payload: Data([0x03, 0xE8])))
        )

        XCTAssertEqual(
            try handler.makeMessage(for: .make(fin: true, opcode: .binary, payload: Data([0x01, 0x02]))),
            .data(Data([0x01, 0x02]))
        )

        XCTAssertNil(
            try handler.makeMessage(for: .make(fin: true, opcode: .ping))
        )
        XCTAssertNil(
            try handler.makeMessage(for: .make(fin: true, opcode: .pong))
        )
        XCTAssertNil(
            try handler.makeMessage(for: .make(fin: true, opcode: .close))
        )
    }

    func testMesages_CreateExpectedFrames() {
        let handler = WSDefaultHandler.make()
        XCTAssertEqual(
            handler.makeFrames(for: .text("Jack of Hearts")),
            [.make(fin: true, opcode: .text, payload: "Jack of Hearts".data(using: .utf8)!)]
        )
        XCTAssertEqual(
            handler.makeFrames(for: .data(Data([0x01, 0x02]))),
            [.make(fin: true, opcode: .binary, payload: Data([0x01, 0x02]))]
        )
    }

    func testResponseFrames() async throws {
        let messages = Messages()
        let handler = WSDefaultHandler.make(handler: messages)

        let frames = try await handler.makeFrames(for: [.fish, .ping, .pong, .chips, .close])

        await XCTAssertEqualAsync(
            try await messages.input.takeNext(),
            .text("Fish")
        )

        await XCTAssertEqualAsync(
            try await messages.input.takeNext(),
            .text("Chips")
        )

        await XCTAssertEqualAsync(
            try await frames.collectAll(),
            [.pong, .close(message: "Goodbye")]
        )
    }

}

private extension WSDefaultHandler {

    static func make(handler: WSMessageHandler = Messages()) -> Self {
        WSDefaultHandler(handler: handler)
    }

    func makeFrames(for frames: [WSFrame]) async throws -> AsyncStream<WSFrame> {
        try await makeFrames(for: .make(frames))
    }
}

private final class Messages: WSMessageHandler, @unchecked Sendable {

    var input: AsyncStream<WSMessage>!
    var output: AsyncStream<WSMessage>.Continuation!

    func makeMessages(for request: AsyncStream<WSMessage>) async throws -> AsyncStream<WSMessage> {
        self.input = request
        return AsyncStream<WSMessage> {
            self.output = $0
        }
    }
}
