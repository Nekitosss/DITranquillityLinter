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
	
	let tokenInfo: [RegistrationAccessor: [RegistrationToken]]
	
	init(substructureList: [SourceKitStructure], file: File, parsingContext: ParsingContext, currentPartName: String?) {
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
				var collectedTokens = ContainerPart.processLoadContainerBodyPart(loadContainerBodyPart: substructure, file: file, content: content, parsingContext: parsingContext, tokenList: &tmpTokenList, currentPartName: currentPartName)
				
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
					let tokenList = RegistrationTokenBuilder.fillTokenListWithInfo(input: registrationToken.tokenList + collectedTokens + tmpTokenList,
																				   typeName: registrationToken.plainTypeName,
																				   parsingContext: parsingContext,
																				   content: content,
																				   file: file)
					let newToken = RegistrationToken(typeName: registrationToken.typeName,
													 plainTypeName: registrationToken.plainTypeName,
													 location: registrationToken.location,
													 tokenList: tokenList)
					assignedRegistrations[String(name[..<firstDotIndex])] = newToken
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
		let tokenList = otherRegistrations + (assignedRegistrationValues as [DIToken])
		self.tokenInfo = ContainerPart.compose(tokenList: tokenList)
	}
	
	private static func compose(tokenList: [DIToken]) -> [RegistrationAccessor: [RegistrationToken]] {
		var registrationTokens: [RegistrationAccessor: [RegistrationToken]] = [:]
		for token in tokenList {
			switch token {
			case let registration as RegistrationToken:
				for token in registration.tokenList {
					guard let aliasToken = token as? AliasToken else { continue }
					registrationTokens[aliasToken.getRegistrationAccessor(), default: []].append(registration)
				}
			case let appendContainer as AppendContainerToken:
				mergeNamedRegistrations(lhs: &registrationTokens, rhs: appendContainer.containerPart.tokenInfo)
			default:
				// Should not be here. All another tokens should be composed in registration and appendContainer tokens
				break
			}
		}
		return registrationTokens
	}
	
	private static func mergeNamedRegistrations(lhs: inout [RegistrationAccessor: [RegistrationToken]], rhs: [RegistrationAccessor: [RegistrationToken]]) {
		for subInfo in rhs {
			lhs[subInfo.key, default: []].append(contentsOf: subInfo.value)
		}
	}
	
	private static func processLoadContainerBodyPart(loadContainerBodyPart: [String : SourceKitRepresentable], file: File, content: NSString, parsingContext: ParsingContext, tokenList: inout [DIToken], currentPartName: String?) -> [DIToken] {
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
		
		if let alias = AliasTokenBuilder.build(functionName: actualName, invocationBody: body, argumentStack: argumentStack, parsingContext: parsingContext, bodyOffset: bodyOffset, file: file) {
			tokenList.append(alias)
		} else if let injection = InjectionTokenBuilder.build(functionName: actualName, invocationBody: body, argumentStack: argumentStack, bodyOffset: bodyOffset, file: file, content: content, substructureList: substructureList) {
			tokenList.append(injection)
		} else if let registration = RegistrationTokenBuilder.build(functionName: actualName, invocationBody: body, argumentStack: argumentStack, tokenList: tokenList, parsingContext: parsingContext, substructureList: substructureList, content: content, bodyOffset: bodyOffset, file: file) {
			tokenList.removeAll()
			result.append(registration)
		} else if let appendContainerToken = AppendContainerTokenBuilder.build(functionName: actualName, parsingContext: parsingContext, argumentStack: argumentStack, bodyOffset: bodyOffset, file: file, currentPartName: currentPartName) {
			result.append(appendContainerToken)
		} else if let isDefaultToken = IsDefaultTokenBuilder.build(functionName: actualName, invocationBody: body, bodyOffset: bodyOffset, file: file) {
			tokenList.append(isDefaultToken)
		} else if argumentStack.contains(where: { $0.value == parsingContext.currentContainerName }) {
			let location = Location(file: file, byteOffset: bodyOffset)
			let info = "You should use \(DIKeywords.diFramework.rawValue) or \(DIKeywords.diPart.rawValue) for injection purposes"
			let invalidCallError = GraphError(infoString: info, location: location)
			parsingContext.errors.append(invalidCallError)
		}
		
		for substructure in substructureList {
			result += processLoadContainerBodyPart(loadContainerBodyPart: substructure, file: file, content: content, parsingContext: parsingContext, tokenList: &tokenList, currentPartName: currentPartName)
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
