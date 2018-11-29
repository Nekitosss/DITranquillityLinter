//
//  HelpersTests.swift
//  DITranquillityLinterTests
//
//  Created by Nikita Patskov on 29/11/2018.
//

import XCTest
@testable import DITranquillityLinterFramework

class HelpersTests: XCTestCase {

	func testParallelArrayErrorThrowing() throws {
		let throwable = NSError(domain: "", code: 0, userInfo: nil)
		do {
			_ = try [1,2,3].parallelMap { _ in
				throw throwable
			}
			XCTFail("Parallel map error did not trwowed")
		} catch {
			XCTAssertEqual(error as NSError, throwable)
		}
	}

}
