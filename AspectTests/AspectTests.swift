//
//  AspectTests.swift
//  AspectTests
//
//  Created by roy.cao on 2019/6/1.
//  Copyright © 2019 roy. All rights reserved.

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import XCTest
@testable import Aspect

public class Test: NSObject {

    @objc dynamic func test(id: Int, name: String) {
        print(id)
        print(name)
    }

    @objc dynamic static func classSelector(id: Int, name: String) {
        print(id)
        print(name)
    }
}

class TestA: Test {

    override dynamic func test(id: Int, name: String) {
        print(id)
        print(name)
    }
}

class TestB: Test {

    override dynamic func test(id: Int, name: String) {
        print(id)
        print(name)
    }
}

class AspectTests: XCTestCase {

    func testHookObjectSelectorByInstance() {
        let test = Test()

        let expectation = self.expectation(description: "Hook the selector test of Test instance ok")
        _ = try? test.hook(selector: #selector(Test.test(id:name:)), strategy: .before) { (_, id: Int, name: String) in
            XCTAssertEqual(id, 1)
            XCTAssertEqual(name, "roy")
            expectation.fulfill()
        }

        test.test(id: 1, name: "roy")

        self.waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testHookObjectSelectorByClasse() {
        let test = Test()

        let expectation = self.expectation(description: "Hook the selector test of Test class ok")
        _ = try? Test.hook(selector: #selector(Test.test(id:name:)), strategy: .before) { (_, id: Int, name: String) in
            XCTAssertEqual(id, 1)
            XCTAssertEqual(name, "roy")
            expectation.fulfill()
        }

        test.test(id: 1, name: "roy")

        self.waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testHookObjectSelectorByClasseAndInstance() {
        let test = Test()

        let expectation = self.expectation(description: "Hook the selector test of Test instance and class ok")
        _ = try? Test.hook(selector: #selector(Test.test(id:name:)), strategy: .before) { (_, id: Int, name: String) in
            XCTAssertEqual(id, 1)
            XCTAssertEqual(name, "roy")
            expectation.fulfill()
        }

        _ = try? test.hook(selector: #selector(Test.test(id:name:)), strategy: .before) { (_, id: Int, name: String) in
            XCTAssertEqual(id, 1)
            XCTAssertEqual(name, "roy")
            expectation.fulfill()
        }

        test.test(id: 1, name: "roy")

        self.waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testHookClassSelector() {
        let expectation = self.expectation(description: "Hook the selector test of Test class ok")
        _ = try? Test.hook(selector: #selector(Test.classSelector(id:name:)), strategy: .before) { (_, id: Int, name: String) in
            XCTAssertEqual(id, 1)
            XCTAssertEqual(name, "roy")
            expectation.fulfill()
        }

        Test.classSelector(id: 1, name: "roy")

        self.waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

    func testHookInTheSameHierarchy() {
        let testA = TestA()

        let expectationA = self.expectation(description: "Hook the selector test of Test class ok")
        _ = try? TestA.hook(selector: #selector(TestA.test(id:name:)), strategy: .before) { (_, id: Int, name: String) in
            XCTAssertEqual(id, 1)
            XCTAssertEqual(name, "roy")
            expectationA.fulfill()
        }

        testA.test(id: 1, name: "roy")

        let testB = TestB()

        let expectationB = self.expectation(description: "Hook the selector test of Test class ok")
        _ = try? TestB.hook(selector: #selector(TestB.test(id:name:)), strategy: .before) { (_, id: Int, name: String) in
            XCTAssertEqual(id, 1)
            XCTAssertEqual(name, "roy")
            expectationB.fulfill()
        }

        testB.test(id: 1, name: "roy")

        self.waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }
}
