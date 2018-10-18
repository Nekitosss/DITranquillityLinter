

import XCTest
@testable import DITranquillityLinterFramework

class RegistrationParserTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
	
	// register{ MyClass<Float>() }
	func testExplicitGenericInitRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestExplicitGenericInitRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass<Float>")
		XCTAssertEqual(registration.plainTypeName, "MyClass")
	}
	
	// register{ MyClass.init() }
	func testExplicitInitRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestExplicitInitRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
	// register{ MyClass() }
	func testImplicitDroppedInitRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestImplicitDroppedInitRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
	// register(MyClass.init)
	func testImplicitInitRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestImplicitInitRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(registration.typeName, "MyClass")
		XCTAssertEqual(injection.name, "string")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// register(MyClass.NestedClass.self)
	func testNestedClassPlainRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestNestedClassPlainRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass.NestedClass")
	}
	
	// .register(MyClass.NestedClass<String>.self)
	func testNestedGenericClassRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestNestedGenericClassRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass.NestedClass<String>")
		XCTAssertEqual(registration.plainTypeName, "MyClass.NestedClass")
	}
	
	// register { MyClass.Nested<Float>() }
	func testNestedExplicitGenericInitRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestNestedExplicitGenericInitRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass.Nested<Float>")
		XCTAssertEqual(registration.plainTypeName, "MyClass.Nested")
	}
	
	// .register1 { MyClass.Nested(string: $0, int: 55) }
	func testNotAllVariablesInjectionInMethod() throws {
		let containerInfo = try findContainerStructure(fileName: "TestNotAllVariablesInjectionInMethod")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(registration.typeName, "MyClass.Nested")
		XCTAssertEqual(injection.name, "string")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .register(MyClass<Float>.self)
	func testPlainGenericRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestPlainGenericRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass<Float>")
		XCTAssertEqual(registration.plainTypeName, "MyClass")
	}
	
	// .register(MyClass.self)
	func testPlainRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestPlainRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
	// let r = container.register(MyClass.self)
	// r.as(MyProtocol.self)
	func testVariableUsedRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestVariableUsedRegistration")
		// maximumRegistrationCount = 2 cause for extra alias
		let registration = try extractRegistrationInfo(containerInfo: containerInfo, maximumRegistrationCount: 2)
		let alias = try extractAliasInfo(registrationToken: registration)
		XCTAssertEqual(alias.typeName, "MyProtocol")
	}
	
	// container.register(MyClass.self)
	// container.register(MySecondClass.self)
	func testSeveralRegistrations() throws {
		let containerInfo = try findContainerStructure(fileName: "TestSeveralRegistrations")
		XCTAssertEqual(containerInfo.tokenInfo.count, 2)
		let registrations = containerInfo.tokenInfo.values.flatMap({ $0 })
		XCTAssertEqual(registrations.count, 2)
		
		// Important to have two different registrations
		let firstTypeName = registrations[0].typeName
		let secondTypeName = registrations[1].typeName
		XCTAssertNotEqual(firstTypeName, secondTypeName)
		let testRegistrationName: (String) -> Bool = {
			$0 == "MyClass" || $0 == "MySecondClass"
		}
		XCTAssertTrue(testRegistrationName(firstTypeName))
		XCTAssertTrue(testRegistrationName(secondTypeName))
	}
	
	// .register1{ MyClass<String>.init(ss: $0) }
	func testExplicitClosureGenericInitializerInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestExplicitClosureGenericInitializerInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(registration.typeName, "MyClass<String>")
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .register1{ MyClass<String>(ss: $0) }
	func testImplicitClosureGenericInitializerInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestImplicitClosureGenericInitializerInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(registration.typeName, "MyClass<String>")
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .register1(MyClass<String>.init)
	func testImplicitPlainGenericInitializerInjection() throws {
		let containerInfo = try findContainerStructure(fileName: "TestImplicitPlainGenericInitializerInjection")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		let injection = try extractInjectionInfo(registrationToken: registration)
		XCTAssertEqual(registration.typeName, "MyClass<String>")
		XCTAssertEqual(injection.name, "ss")
		XCTAssertEqual(injection.typeName, "String")
	}
	
	// .register(MyClassTypealias.self) where MyClassTypealias = MyClass
	func testTypealiasedClassRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestTypealiasedClassRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
	// container.register { MyClass.staticLet } where static let staticLet: MyClass = .init()
	func testStaticVariableRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestStaticVariableRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}
	
	// .register(MyClass.init(nibName:bundle:))
	func testOuterUIKitMethodRegistration() throws {
		let containerInfo = try findContainerStructure(fileName: "TestOuterUIKitMethodRegistration")
		let registration = try extractRegistrationInfo(containerInfo: containerInfo)
		XCTAssertEqual(registration.typeName, "MyClass")
	}

}
