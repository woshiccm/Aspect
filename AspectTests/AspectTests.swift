//
//  AspectTests.swift
//  AspectTests
//
//  Created by roy.cao on 2019/6/1.
//  Copyright © 2019 roy. All rights reserved.
//

import XCTest
@testable import Aspect

public class Test: NSObject {

    @objc dynamic func test(id: Int, name: String) {
        print(id)
        print(name)
    }
}

class AspectTests: XCTestCase {

    func testHook() {
        let test = Test()

        let expectation = self.expectation(description: "Hook the selector test of Test instance ok")
        test.hook(selector: #selector(Test.test(id:name:)), strategy: .before) { (_, id: Int, name: String) in
            XCTAssertEqual(id, 1)
            XCTAssertEqual(name, "roy")
            expectation.fulfill()
        }

        test.test(id: 1, name: "roy")

        self.waitForExpectations(timeout: 2) { error in
            XCTAssertNil(error)
        }
    }

}
