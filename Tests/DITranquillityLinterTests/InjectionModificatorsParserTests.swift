

import XCTest
@testable import DITranquillityLinterFramework

class InjectionModificatorsParserTests: XCTestCase {
	
	// .injection(\.ss) { by(tag: MyTag.self, on: $0) }
	func testTaggedModificatorKeyPathInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTaggedModificatorKeyPathInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.tag, "MyTag")
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "MyProtocol")
	}
	
	// .injection { $0.ss = by(tag: MyTag.self, on: $1) as String }
	func testTypedAndTaggedVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypedAndTaggedVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
		XCTAssertEqual(injection.tag, "MyTag")
	}
	
	// .injection { $0.ss = $1 as String }
	func testTypedVariableInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypedVariableInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .register1 { MyClass<String>.init(ss: by(tag: MyTag.self, on: $0)) }
	func testTaggedInitializerInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTaggedInitializerInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.tag, "MyTag")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .register1 { MyClass(ss: $0 as MyAnotherClass) }
	func testTypedInitializerInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypedInitializerInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(injection.typeName, "MyAnotherClass")
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
	// .injection(\.ss) { many($0) }
	func testManyInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestManyInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertTrue(injection.isMany)
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "MyProtocol")
	}
}
