//
//  URLSession+AsyncTests.swift
//  FlyingFox
//
//  Created by Simon Whitty on 22/02/2022.
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
import XCTest
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class URLSessionAsyncTests: XCTestCase {

    func testURLSession_MakesRequest() async throws {
        let request = URLRequest(url: URL(string: "https://pie.dev/status/208")!)
        let (_, response) = try await URLSession.shared.getData(for: request, forceFallback: false)

        XCTAssertEqual(
            (response as! HTTPURLResponse).statusCode,
            208
        )
    }

    func testURLSessionFallback_MakesRequest() async throws {
        let request = URLRequest(url: URL(string: "https://pie.dev/status/208")!)
        let (_, response) = try await URLSession.shared.getData(for: request, forceFallback: true)

        XCTAssertEqual(
            (response as! HTTPURLResponse).statusCode,
            208
        )
    }

    func testURLSessionFallback_ReturnsError() async throws {
        let request = URLRequest(url: URL(string: "https://flying.fox.invalid/")!)
        await AsyncAssertThrowsError(try await URLSession.shared.getData(for: request, forceFallback: true), of: URLError.self)
    }

    func testURLSession_CancelsRequest() async throws {
        let request = URLRequest(url: URL(string: "https://httpstat.us/200?sleep=10000")!)

        let task = Task {
            _ = try await URLSession.shared.getData(for: request)
        }

        task.cancel()

        await AsyncAssertThrowsError(try await task.value, of: URLError.self) {
            XCTAssertEqual($0.code, .cancelled)
        }
    }

    func testURLSessionFallback_CancelsRequest() async throws {
        let request = URLRequest(url: URL(string: "https://httpstat.us/200?sleep=10000")!)

        let task = Task {
            _ = try await URLSession.shared.getData(for: request, forceFallback: true)
        }

        task.cancel()

        await AsyncAssertThrowsError(try await task.value, of: URLError.self) {
            XCTAssertEqual($0.code, .cancelled)
        }
    }
}
