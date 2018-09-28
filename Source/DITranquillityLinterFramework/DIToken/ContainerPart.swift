//
//  ContainerPart.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework
import xcodeproj


// DIPart, DIFramework
final class ContainerPart {
	
	let tokenList: [DIToken]
	
	init(substructureList: [SourceKitStructure], file: File, collectedInfo: [String: Type], currentPartName: String?) {
		let content = file.contents.bridge()
		var tmpTokenList: [DIToken] = []
		var assignedRegistrations: [String: RegistrationToken] = [:]
		var otherRegistrations: [DIToken] = []
		var nextAssignee: String?
		
		for substructure in substructureList {
			tmpTokenList.removeAll()
			let assignee = nextAssignee
			nextAssignee = nil
			guard let kind: String = substructure.get(.kind) else { continue }
			switch kind {
			case SwiftExpressionKind.call.rawValue:
				// Get all tokens
				var collectedTokens = ContainerPart.processLoadContainerBodyPart(loadContainerBodyPart: substructure, file: file, content: content, collectedInfo: collectedInfo, tokenList: &tmpTokenList, currentPartName: currentPartName)
				
				if let registrationTokenIndex = collectedTokens.index(where: { $0 is RegistrationToken }) {
					// get registration token. Should be 0 or 1 count. Remember that container.append(part:).register() is available
					let registrationToken = collectedTokens.remove(at: registrationTokenIndex) as! RegistrationToken
					
					if let assignee = assignee {
						assignedRegistrations[assignee] = registrationToken
					} else {
						otherRegistrations.append(registrationToken)
					}
					otherRegistrations.append(contentsOf: collectedTokens)
					
				} else if let name: String = substructure.get(.name), let firstDotIndex = name.firstIndex(of: "."), let registrationToken = assignedRegistrations[String(name[..<firstDotIndex])] {
					// something like:
					// let r = container.register(_:)  (processed earlier)
					// r.inject(_:)  (processed in that if block)
					registrationToken.tokenList.append(contentsOf: collectedTokens + tmpTokenList)
				} else {
					// container.append(part:) for example
					otherRegistrations.append(contentsOf: collectedTokens)
				}
			case SwiftDeclarationKind.varLocal.rawValue:
				// for swift complex source code resolving
				// let r = container.register(_:)
				// "r" is assignee name
				guard let name: String = substructure.get(.name)
					else { continue }
				
				if let registration = assignedRegistrations[name] {
					// For handling:
					// var r = container.register(_:)
					// r.injectSomething...
					// r = container.register1(_:)
					otherRegistrations.append(registration)
				}
				nextAssignee = name
			default:
				break
			}
		}
	
		let assignedRegistrationValues = Array(assignedRegistrations.values)
		self.tokenList = otherRegistrations + (assignedRegistrationValues as [DIToken])
	}
	
	private static func processLoadContainerBodyPart(loadContainerBodyPart: [String : SourceKitRepresentable], file: File, content: NSString, collectedInfo: [String: Type], tokenList: inout [DIToken], currentPartName: String?) -> [DIToken] {
		var result: [DIToken] = []
		
		guard let kind: String = loadContainerBodyPart.get(.kind),
			let name: String = loadContainerBodyPart.get(.name),
			let bodyOffset: Int64 = loadContainerBodyPart.get(.bodyOffset),
			let bodyLength: Int64 = loadContainerBodyPart.get(.bodyLength),
			kind == SwiftExpressionKind.call.rawValue
			else { return result }
		let body = content.substringUsingByteRange(start: bodyOffset, length: bodyLength)!
		let actualName = extractActualFuncionInvokation(name: name)
		
		let substructureList = loadContainerBodyPart.substructures ?? []
		let argumentStack = argumentInfo(substructures: substructureList, content: content)
		
		if let alias = AliasToken(functionName: actualName, invocationBody: body, argumentStack: argumentStack, bodyOffset: bodyOffset, file: file) {
			tokenList.append(alias)
		} else if let injection = InjectionToken(functionName: actualName, invocationBody: body, argumentStack: argumentStack, bodyOffset: bodyOffset, file: file, substructureList: substructureList) {
			tokenList.append(injection)
		} else if let registration = RegistrationToken(functionName: actualName, invocationBody: body, argumentStack: argumentStack, tokenList: tokenList, collectedInfo: collectedInfo, substructureList: substructureList, content: content, bodyOffset: bodyOffset, file: file) {
			tokenList.removeAll()
			result.append(registration)
		} else if let appendContainerToken = AppendContainerToken(functionName: actualName, collectedInfo: collectedInfo, argumentStack: argumentStack, bodyOffset: bodyOffset, file: file, currentPartName: currentPartName) {
			result.append(appendContainerToken)
		}
		
		for substructure in substructureList {
			result += processLoadContainerBodyPart(loadContainerBodyPart: substructure, file: file, content: content, collectedInfo: collectedInfo, tokenList: &tokenList, currentPartName: currentPartName)
		}
		return result
	}
	
	static func argumentInfo(substructures: [SourceKitStructure], content: NSString) -> [ArgumentInfo] {
		var argumentStack = [ArgumentInfo]()
		let substructures = substructures.filter({ $0.get(.kind, of: String.self) == SwiftExpressionKind.argument.rawValue })
		
		for structure in substructures {
			guard let bodyOffset: Int64 = structure.get(.bodyOffset),
				let bodyLength: Int64 = structure.get(.bodyLength),
				let nameLength: Int64 = structure.get(.nameLength),
				let nameOffset: Int64 = structure.get(.nameOffset)
				else { continue }
			let body = content.substringUsingByteRange(start: bodyOffset, length: bodyLength) ?? ""
			let name = nameLength > 0 ? content.substringUsingByteRange(start: nameOffset, length: nameLength) ?? "" : ""
			let argument = ArgumentInfo(name: name, value: body, structure: structure)
			argumentStack.append(argument)
		}
		return argumentStack
	}
	
	static func extractActualFuncionInvokation(name: String) -> String {
		guard let dotIndex = name.reversed().index(of: ".") else {
			return name
		}
		return String(name[dotIndex.base...])
	}
	
}
