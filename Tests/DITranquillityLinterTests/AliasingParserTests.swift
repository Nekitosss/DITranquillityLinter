

import XCTest
@testable import DITranquillityLinterFramework

class AliasingParserTests: XCTestCase {
	
	override func tearDown() {
		clearTestArtifacts()
	}
	
	// .as(MyProtocol.self)
	func testPlainAliasing() throws {
		let containerInfo = try findContainerStructure(fileName: "TestPlainAliasing")
		// maximumRegistrationCount = 2 cause for extra alias
		let registration = try extractRegistrationInfo(containerInfo: containerInfo, maximumRegistrationCount: 2)
		let alias = try extractAliasInfo(registrationToken: registration)
		XCTAssertEqual(alias.typeName, "MyProtocol")
	}
	
	// .as(MyProtocol.self, tag: MyTag.self)
	func testTaggedAliasing() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTaggedAliasing")
		// maximumRegistrationCount = 2 cause for extra alias
		let registration = try extractRegistrationInfo(containerInfo: containerInfo, maximumRegistrationCount: 2)
		let alias = try extractAliasInfo(registrationToken: registration)
		XCTAssertEqual(alias.typeName, "MyProtocol")
		XCTAssertEqual(alias.tag, "MyTag")
	}
	
	// .as((MyProtocol & MyProtocol2).self)
	func testProtocolCompositionAliasing() throws {
		let containerInfo = try findContainerStructure(fileName: "TestProtocolCompositionAliasing")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo, maximumRegistrationCount: 2)
		let alias = try extractAliasInfo(registrationToken: registration)
		XCTAssertEqual(alias.typeName, "MyProtocol & MyProtocol2")
	}
	
	// .as(MyProtocolComposition.self) where MyProtocolComposition = (MyProtocol & MyProtocol2)
	func testWrappedProtocolCompositionAliasing() throws {
		let containerInfo = try findContainerStructure(fileName: "TestWrappedProtocolCompositionAliasing")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo, maximumRegistrationCount: 2)
		let alias = try extractAliasInfo(registrationToken: registration)
		XCTAssertEqual(alias.typeName, "MyProtocol & MyProtocol2")
	}
	
	// .as(MyProtocolTypealias.self) where MyProtocolTypealias = MyProtocol
	func testTypealiasedRegistrationAliasing() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypealiasedRegistrationAliasing")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo, maximumRegistrationCount: 2)
		let alias = try extractAliasInfo(registrationToken: registration)
		XCTAssertEqual(alias.typeName, "MyProtocol")
	}

}
