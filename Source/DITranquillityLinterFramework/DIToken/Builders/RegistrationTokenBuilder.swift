//
//  RegistrationTokenBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 28/09/2018.
//

import Foundation
import ASTVisitor

/// Trying to create RegsitrationToken. Resolves containing InjectionToken types.
final class RegistrationTokenBuilder: TokenBuilder {
	
	typealias RegistrationInfo = (typeName: String, plainTypeName: String, tokenList: [DITokenConvertible])
	
	private let typeFinder = TypeFinder()
	
	func build(using info: TokenBuilderInfo) -> DITokenConvertible? {
		guard info.functionName == DIKeywords.initializerRegister.rawValue || info.functionName == DIKeywords.typeRegister.rawValue,
			let declrefExpr = info.node[.dotSyntaxCallExpr][.declrefExpr].getSeveral()?.first?.typedNode.unwrap(DeclrefExpression.self),
			let astLocation = declrefExpr.location
			else { return nil }
		let location = Location(visitorLocation: astLocation)
		
		var registrationInfo: RegistrationInfo = ("", "", info.tokenList)
		
		for substitution in declrefExpr.substitution {
			if substitution.key == "Impl" {
				registrationInfo.typeName = substitution.value
			} else if !substitution.value.isEmpty {
				let injection = InjectionToken(name: "",
											   typeName: substitution.value,
											   plainTypeName: "",
											   cycle: false,
											   optionalInjection: false,
											   methodInjection: true,
											   modificators: [],
											   location: location)
				registrationInfo.tokenList.append(injection)
			}
		}
		
		let aliasToken = AliasToken(typeName: registrationInfo.typeName, tag: "", location: location)
		registrationInfo.tokenList.append(aliasToken)
		
		return RegistrationToken(typeName: registrationInfo.typeName,
								 plainTypeName: registrationInfo.plainTypeName,
								 location: location,
								 tokenList: registrationInfo.tokenList.map({ $0.diTokenValue }))
		
//
//		// TODO: process generics here
//		if let typedRegistration = info.invocationBody.firstMatch(RegExp.trailingTypeInfo) {
//			// container.register(MyClass.self)
//			registrationInfo.typeName = typedRegistration.droppedDotSelf()
//			registrationInfo.plainTypeName = TypeFinder.parseTypeName(name: registrationInfo.typeName).plainTypeName
//		}
//
//		if let extractedInfo = extractPlainRegistration(using: info) ?? extractClosureRegistration(using: info) {
//			registrationInfo.typeName = extractedInfo.typeName
//			registrationInfo.plainTypeName = extractedInfo.plainTypeName
//			registrationInfo.tokenList += extractedInfo.tokenList
//		}
//		registrationInfo.typeName = info.parsingContext.collectedInfo[registrationInfo.typeName]?.name ?? registrationInfo.typeName
//		registrationInfo.typeName = registrationInfo.typeName.trimmingCharacters(in: .whitespacesAndNewlines)
//		registrationInfo.plainTypeName = registrationInfo.plainTypeName.trimmingCharacters(in: .whitespacesAndNewlines)
//
//		// Class registration by default available by its own type without tag.
//		let location = Location(file: info.file, byteOffset: info.bodyOffset)
		
//
//		registrationInfo.tokenList = self.fillTokenListWithInfo(input: registrationInfo.tokenList, registrationTypeName: registrationInfo.typeName, parsingContext: info.parsingContext, content: info.content, file: info.file)
	}
	
	
//	private func extractPlainRegistration(using info: TokenBuilderInfo) -> RegistrationInfo? {
//		// container.register(MyClass.init)
//		guard info.substructureList.isEmpty,
//			!info.invocationBody.hasSuffix(".self"),
//			let dotIndex = info.invocationBody.lastIndex(of: ".")
//			else { return nil }
//
//		let (typeName, fullTypeName, genericType) = TypeFinder.parseTypeName(name: info.invocationBody)
//
//		let signatureText = String(info.invocationBody[info.invocationBody.index(after: dotIndex)...])
//		let methodSignature = MethodSignature(name: signatureText, injectableArgumentInfo: [], injectionModificators: [:])
//		let tokenList = typeFinder.findMethodInfo(methodSignature: methodSignature, initialObjectName: typeName, parsingContext: info.parsingContext, file: info.file, genericType: genericType, methodCallBodyOffset: info.bodyOffset, forcedAllInjection: true) ?? []
//
//		return (fullTypeName, typeName, tokenList)
//	}
//
//
//	private func extractClosureRegistration(using info: TokenBuilderInfo) -> RegistrationInfo? {
//		// container.register { MyClass.init($0, $1) }
//		guard
//			let substructure = info.substructureList.first,
//			info.substructureList.count == 1,
//			substructure.isKind(of: SwiftExpressionKind.closure)
//			else { return nil }
//
//		if let expressionCallInitSubstructure = substructure.substructures.first,
//			let name: String = expressionCallInitSubstructure.get(.name),
//			expressionCallInitSubstructure.isKind(of: SwiftExpressionKind.call) {
//
//			return extractStaticMethodRegistration(expressionCallInitSubstructure: expressionCallInitSubstructure, name: name, parsingContext: info.parsingContext, content: info.content, file: info.file, bodyOffset: info.bodyOffset)
//
//		} else if let body = substructure.body(using: info.content)?.trimmingCharacters(in: .whitespacesAndNewlines) {
//			return extractStaticVariableRegistration(body: body, parsingContext: info.parsingContext)
//		}
//
//		return nil
//	}
//
//
//	// TODO: Currently only .init extracts. Should handle all other static methods
//	private func extractStaticMethodRegistration(expressionCallInitSubstructure: SourceKitStructure, name: String, parsingContext: GlobalParsingContext, content: NSString, file: File, bodyOffset: Int64) -> RegistrationInfo {
//		let (typeName, fullTypeName, genericType) = TypeFinder.parseTypeName(name: name)
//
//		// Handle MyClass.NestedClass()
//		// NestedClass can be class name, but it also can be expression call. So we check is MyClass.NestedClass available class name
//		// and if if exists, adds ".init" at the end of initialization call
//		let nameWithInitializer = parsingContext.collectedInfo[name] != nil && !name.hasSuffix(".init") ? name + ".init" : name
//		let methodName = TypeFinder.restoreMethodName(initial: nameWithInitializer)
//		let signature = self.typeFinder.restoreSignature(name: methodName, substructureList: expressionCallInitSubstructure.substructures, content: content)
//		let tokenList = self.typeFinder.findMethodInfo(methodSignature: signature, initialObjectName: typeName, parsingContext: parsingContext, file: file, genericType: genericType, methodCallBodyOffset: bodyOffset, forcedAllInjection: false) ?? []
//
//		return (fullTypeName, typeName, tokenList)
//	}
//
//
//	private func extractStaticVariableRegistration(body: String, parsingContext: GlobalParsingContext) -> RegistrationInfo? {
//		guard let lastDotIndex = body.lastIndex(of: ".") else {
//			return nil
//		}
//		let typeContainerName = String(body[..<lastDotIndex])
//		let staticVariableName = String(body[body.index(after: lastDotIndex)...])
//		if let (typeName, plainTypeName, _) = self.typeFinder.findArgumentTypeInfo(typeName: typeContainerName, tokenName: staticVariableName, parsingContext: parsingContext, modificators: []) {
//			return (typeName, plainTypeName, [])
//		}
//		return nil
//	}
//
//
//	func fillTokenListWithInfo(input: [DITokenConvertible], registrationTypeName: String, parsingContext: GlobalParsingContext, content: NSString, file: File) -> [DITokenConvertible] {
//		// Recursively walk through all classes and find injection type
//		return input.reduce(into: []) { result, token in
//			// injectionToken.typeName.isEmpty always really empty here (in alpha at least)
//			guard var injectionToken = token as? InjectionToken, injectionToken.typeName.isEmpty else {
//				result.append(token)
//				return
//			}
//			if let foundedInfo = self.typeFinder.findArgumentTypeInfo(typeName: registrationTypeName, tokenName: injectionToken.name, parsingContext: parsingContext, modificators: injectionToken.modificators) {
//				injectionToken.typeName = foundedInfo.typeName
//				injectionToken.plainTypeName = foundedInfo.plainTypeName
//				injectionToken.optionalInjection = foundedInfo.optionalInjection
//				result.append(injectionToken)
//			} else {
//				// after "findMethodTypeInfo" we not input type info. We write new tokens.
//				// so we no need append old
//				result += self.typeFinder.findMethodTypeInfo(typeName: registrationTypeName, parsingContext: parsingContext, content: content, file: file, token: injectionToken)
//			}
//		}
//	}
	
}
