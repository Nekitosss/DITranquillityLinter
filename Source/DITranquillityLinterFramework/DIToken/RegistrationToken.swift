//
//  RegistrationToken.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/08/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework
import xcodeproj

class RegistrationToken: DIToken {
	
	var typeName: String = ""
	var tokenList: [DIToken] = []
	
	init?(functionName: String, invocationBody: String, argumentStack: [ArgumentInfo], tokenList: [DIToken], collectedInfo: [String: Type], substructureList: [[String : SourceKitRepresentable]], content: NSString, bodyOffset: Int64, file: File) {
		guard functionName == DIKeywords.register.rawValue || functionName == DIKeywords.register1.rawValue else {
			return nil
		}
		self.tokenList = tokenList
		if let typedRegistration = invocationBody.firstMatch(RegExp.trailingTypeInfo) {
			// container.register(MyClass.self)
			typeName = typedRegistration.droppedDotSelf()
		}
		extractPlainRegistration(substructureList: substructureList, invocationBody: invocationBody, collectedInfo: collectedInfo, file: file, bodyOffset: bodyOffset)
		extractClosureRegistration(substructureList: substructureList, collectedInfo: collectedInfo, content: content, file: file, bodyOffset: bodyOffset)
		fillTokenListWithInfo(collectedInfo: collectedInfo, content: content, file: file)
	}
	
	private func extractPlainRegistration(substructureList: [SourceKitStructure], invocationBody: String, collectedInfo: [String: Type], file: File, bodyOffset: Int64) {
		// container.register(MyClass.init)
		guard substructureList.isEmpty && !invocationBody.hasSuffix(".self") else { return }
		let (typeName, fullTypeName, genericType) = self.parseTypeName(name: invocationBody)
		guard let dotIndex = invocationBody.reversed().index(of: ".")?.base else { return }
		let signatureText = String(invocationBody[invocationBody.index(after: dotIndex)...])
		let methodSignature = MethodSignature(name: signatureText, injectableArgumentInfo: [], injectionModificators: [:])
		if let methodInjection = MethodFinder.findMethodInfo(methodSignature: methodSignature, initialObjectName: typeName, collectedInfo: collectedInfo, file: file, genericType: genericType, methodCallBodyOffset: bodyOffset) {
			self.tokenList += methodInjection as [DIToken]
		}
		self.typeName = fullTypeName
	}
	
	private func extractClosureRegistration(substructureList: [SourceKitStructure], collectedInfo: [String: Type], content: NSString, file: File, bodyOffset: Int64) {
		// container.register { MyClass.init($0, $1) }
		guard substructureList.count == 1 else { return }
		var substructure = substructureList[0]
		guard let closureKind: String = substructure.get(.kind), closureKind == SwiftExpressionKind.closure.rawValue else { return }
		guard let expressionCallInitSubstructure = (substructure.substructures ?? []).first else { return }
		substructure = expressionCallInitSubstructure
		
		guard let kind: String = substructure.get(.kind),
			let name: String = substructure.get(.name),
			kind == SwiftExpressionKind.call.rawValue
			else { return }
		let (typeName, fullTypeName, genericType) = self.parseTypeName(name: name)
		self.typeName = fullTypeName
		let argumentsSubstructure = substructure.get(.substructure, of: [SourceKitStructure].self) ?? []
		let methodName = restoreMethodName(registrationName: name)
		let signature = restoreSignature(name: methodName, substructureList: argumentsSubstructure, content: content)
		if let methodInjection = MethodFinder.findMethodInfo(methodSignature: signature, initialObjectName: typeName, collectedInfo: collectedInfo, file: file, genericType: genericType, methodCallBodyOffset: bodyOffset) {
			self.tokenList += methodInjection as [DIToken]
		}
	}
	
	private func parseTypeName(name: String) -> (typeName: String, fullTypeName: String, genericType: GenericType?) {
		let name = name.droppedDotInit()
		if let genericType = Composer.parseGenericType(name) {
			return (genericType.name, name, genericType)
		} else {
			return (name, name, nil)
		}
	}
	
	private func restoreMethodName(registrationName: String) -> String {
		if let dotIndex = registrationName.reversed().index(of: ".")?.base {
			return String(registrationName[dotIndex...])
		} else {
			return ""
		}
	}
	
	private func restoreSignature(name: String, substructureList: [[String: SourceKitRepresentable]], content: NSString) -> MethodSignature {
		var signatureName = name.isEmpty ? "init" : name
		var injectableArguments: [(Int, Int64)] = []
		var injectionModificators: [Int : [InjectionModificator]] = [:]
		if !substructureList.isEmpty {
			signatureName.append("(")
		}
		var argumentNumber = 0
		for substucture in substructureList {
			
			let name = substucture.get(.name, of: String.self) ?? "_"
			guard let kind: String = substucture.get(.kind),
				let bodyLenght: Int64 = substucture.get(.bodyLength),
				let bodyOffset: Int64 = substucture.get(.bodyOffset),
				kind == SwiftExpressionKind.argument.rawValue,
				let body = content.substringUsingByteRange(start: bodyOffset, length: bodyLenght)
				else { continue }
			
			if body.firstMatch(RegExp.implicitClosureArgument) != nil {
				injectableArguments.append((argumentNumber, bodyOffset))
			}
			if let forcedType = body.firstMatch(RegExp.forcedType)?.trimmingCharacters(in: .whitespacesAndNewlines) {
				injectionModificators[argumentNumber, default: []].append(InjectionModificator.typed(forcedType))
			}
			if let taggedInjection = InjectionToken.parseTaggedInjection(structure: substucture, content: content) {
				injectionModificators[argumentNumber, default: []].append(contentsOf: taggedInjection)
			}
			
			signatureName += name + ":"
			argumentNumber += 1
		}
		if !substructureList.isEmpty {
			signatureName.append(")")
		}
		return MethodSignature(name: signatureName, injectableArgumentInfo: injectableArguments, injectionModificators: injectionModificators)
	}
	
	func fillTokenListWithInfo(collectedInfo: [String: Type], content: NSString, file: File) {
		// Recursively walk through all classes and find injection type
		let injectionTokens = tokenList.compactMap({ $0 as? InjectionToken })
		for token in injectionTokens where token.typeName.isEmpty {
			findArgumentTypeInfo(type: collectedInfo[typeName], token: token)
		}
		for token in injectionTokens where token.typeName.isEmpty {
			findMethodTypeInfo(collectedInfo: collectedInfo, content: content, file: file, token: token)
		}
	}
	
	private func findMethodTypeInfo(collectedInfo: [String: Type], content: NSString, file: File, token: InjectionToken) {
		if let substructure = token.injectionSubstructureList.last,
			var methodName: String = substructure.get(.name),
			let offset: Int64 = substructure.get(.offset) {
			if let dotIndex = methodName.index(of: ".") {
				methodName = String(methodName[methodName.index(after: dotIndex)...])
			}
			let argumentsSubstructure = substructure.get(.substructure, of: [SourceKitStructure].self) ?? []
			let signature = restoreSignature(name: methodName, substructureList: argumentsSubstructure, content: content)
			// TODO: Method generic type unwrapping
			if let methodInjection = MethodFinder.findMethodInfo(methodSignature: signature, initialObjectName: typeName, collectedInfo: collectedInfo, file: file, genericType: nil, methodCallBodyOffset: offset) {
				self.tokenList += methodInjection as [DIToken]
			}
		}
	}
	
	@discardableResult
	private func findArgumentTypeInfo(type: Type?, token: InjectionToken) -> Bool {
		guard let ownerType = type else { return false }
		if let variable = ownerType.variables.first(where: { $0.name == token.name }) {
			token.typeName = variable.unwrappedTypeName
			token.optionalInjection = variable.isOptional
			return true
		}
		for parent in ownerType.inherits {
			if findArgumentTypeInfo(type: parent.value, token: token) {
				return true
			}
		}
		return false
	}
	
}
