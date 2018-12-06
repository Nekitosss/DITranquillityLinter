//
//  ContainerPartBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/11/2018.
//


import SourceKittenFramework
import Foundation

final class ContainerPartBuilder {
	
	static func argumentInfo(substructures: [SourceKitStructure], content: NSString) -> [ArgumentInfo] {
		return substructures.compactMap { structure in
			guard
				let kind: String = structure.get(.kind),
				kind == SwiftExpressionKind.argument.rawValue,
				let bodyOffset: Int64 = structure.get(.bodyOffset),
				let bodyLength: Int64 = structure.get(.bodyLength),
				let nameLength: Int64 = structure.get(.nameLength),
				let nameOffset: Int64 = structure.get(.nameOffset)
				else { return nil }
			let body = content.substringUsingByteRange(start: bodyOffset, length: bodyLength) ?? ""
			let name = nameLength > 0 ? content.substringUsingByteRange(start: nameOffset, length: nameLength) ?? "_" : "_"
			return ArgumentInfo(name: name, value: body, structure: structure)
		}
	}
	
	
	private let file: File
	private let parsingContext: ParsingContext
	private let currentPartName: String?
	private let content: NSString
	private let allTokenBuilders: [TokenBuilder]
	private let registrationTokenBuilder: RegistrationTokenBuilder
	
	
	init(file: File, parsingContext: ParsingContext, currentPartName: String?) {
		self.file = file
		self.parsingContext = parsingContext
		self.currentPartName = currentPartName
		self.content = file.contents.bridge()
		self.registrationTokenBuilder = RegistrationTokenBuilder()
		self.allTokenBuilders = [AliasTokenBuilder(),
								 InjectionTokenBuilder(),
								 self.registrationTokenBuilder,
								 IsDefaultTokenBuilder(),
								 AppendContainerTokenBuilder()
		]
	}
	
	
	func build(substructureList: [SourceKitStructure]) -> [RegistrationAccessor: [RegistrationToken]] {
		var intermediateTokenList: [DIToken] = []
		var assignedRegistrations: [String: RegistrationToken] = [:]
		var otherRegistrations: [DIToken] = []
		var nextAssignee: String?
		
		for substructure in substructureList {
			processRegistrationChain(substructure: substructure,
									 intermediateTokenList: &intermediateTokenList,
									 nextAssignee: &nextAssignee,
									 otherRegistrations: &otherRegistrations,
									 assignedRegistrations: &assignedRegistrations)
		}
		
		let assignedRegistrationValues = Array(assignedRegistrations.values)
		let tokenList = otherRegistrations + (assignedRegistrationValues as [DIToken])
		return compose(tokenList: tokenList)
	}
	
	
	private func processRegistrationChain(substructure: SourceKitStructure, intermediateTokenList: inout [DIToken], nextAssignee: inout String?, otherRegistrations: inout [DIToken], assignedRegistrations: inout [String: RegistrationToken]) {
		intermediateTokenList.removeAll()
		let assignee = nextAssignee
		nextAssignee = nil
		guard let kind: String = substructure.get(.kind) else {
			return
		}
		
		switch kind {
		case SwiftExpressionKind.call.rawValue:
			processExpressionKindCall(use: substructure, assignee: assignee, intermediateTokenList: &intermediateTokenList, otherRegistrations: &otherRegistrations, assignedRegistrations: &assignedRegistrations)
		case SwiftDeclarationKind.varLocal.rawValue:
			nextAssignee = processVarLocalDeclarationKind(use: substructure, otherRegistrations: &otherRegistrations, assignedRegistrations: assignedRegistrations)
				?? nextAssignee
		default:
			break
		}
	}
	
	
	private func processExpressionKindCall(use substructure: SourceKitStructure, assignee: String?, intermediateTokenList: inout [DIToken], otherRegistrations: inout [DIToken], assignedRegistrations: inout [String: RegistrationToken]) {
		// Get all tokens
		var collectedTokens = self.processLoadContainerBodyPart(loadContainerBodyPart: substructure, tokenList: &intermediateTokenList)
		
		if let registrationTokenIndex = collectedTokens.index(where: { $0 is RegistrationToken }) {
			// get registration token. Should be 0 or 1 count. Remember that container.append(part:).register() is available
			// swiftlint:disable force_cast
			let registrationToken = collectedTokens.remove(at: registrationTokenIndex) as! RegistrationToken
			// swiftlint:enable force_cast
			
			if let assignee = assignee {
				assignedRegistrations[assignee] = registrationToken
			} else {
				otherRegistrations.append(registrationToken)
			}
			otherRegistrations.append(contentsOf: collectedTokens)
			
		} else if let name: String = substructure.get(.name),
			let firstDotIndex = name.firstIndex(of: "."),
			let registrationToken = assignedRegistrations[String(name[..<firstDotIndex])] {
			// something like:
			// let r = container.register(_:)  (processed earlier)
			// r.inject(_:)  (processed in that if block)
			let inputTokenList = registrationToken.tokenList + collectedTokens + intermediateTokenList
			let tokenList = self.registrationTokenBuilder.fillTokenListWithInfo(input: inputTokenList,
																				registrationTypeName: registrationToken.plainTypeName,
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
	}
	
	/// For swift complex source code resolving
	///
	/// ```let r = container.register(_:)```
	///
	/// "r" is assignee name
	private func processVarLocalDeclarationKind(use substructure: SourceKitStructure, otherRegistrations: inout [DIToken], assignedRegistrations: [String: RegistrationToken]) -> String? {
		guard let name: String = substructure.get(.name) else {
			return nil
		}
		if let registration = assignedRegistrations[name] {
			// For handling:
			// var r = container.register(_:)
			// r.injectSomething...
			// r = container.register1(_:)
			otherRegistrations.append(registration)
		}
		return name
	}
	
	
	private func compose(tokenList: [DIToken]) -> [RegistrationAccessor: [RegistrationToken]] {
		return tokenList.reduce(into: [:]) { result, token in
			switch token {
			case let registration as RegistrationToken:
				registration.tokenList
					.compactMap { $0 as? AliasToken }
					.forEach { result[$0.getRegistrationAccessor(), default: []].append(registration) }
				
			case let appendContainer as AppendContainerToken:
				appendContainer.containerPart.tokenInfo
					.forEach { result[$0, default: []] += $1 }
				
			default:
				// Should not be here. All another tokens should be composed in registration and appendContainer tokens
				break
			}
		}
	}
	
	
	private func processLoadContainerBodyPart(loadContainerBodyPart: SourceKitStructure, tokenList: inout [DIToken]) -> [DIToken] {
		guard let info = self.getTokenInfo(from: loadContainerBodyPart, tokenList: tokenList) else {
			return []
		}
		
		var result: [DIToken] = []
		if let token = tryBuildToken(use: info) {
			if token.isIntermediate {
				tokenList.append(token)
			} else {
				tokenList.removeAll()
				result.append(token)
			}
		} else if info.argumentStack.contains(where: { $0.value == parsingContext.currentContainerName }) {
			let message = "You should use \(DIKeywords.diFramework.rawValue) or \(DIKeywords.diPart.rawValue) for injection purposes"
			let invalidCallError = GraphError(infoString: message, location: info.location)
			parsingContext.errors.append(invalidCallError)
		}
		
		for substructure in loadContainerBodyPart.substructures {
			result += processLoadContainerBodyPart(loadContainerBodyPart: substructure, tokenList: &tokenList)
		}
		return result
	}
	
	
	private func getTokenInfo(from loadContainerBodyPart: SourceKitStructure, tokenList: [DIToken]) -> TokenBuilderInfo? {
		guard let kind: String = loadContainerBodyPart.get(.kind),
			let name: String = loadContainerBodyPart.get(.name),
			let bodyOffset: Int64 = loadContainerBodyPart.get(.bodyOffset),
			let bodyLength: Int64 = loadContainerBodyPart.get(.bodyLength),
			kind == SwiftExpressionKind.call.rawValue,
			let body = content.substringUsingByteRange(start: bodyOffset, length: bodyLength)
			else { return nil }
		let functionName = TypeFinder.restoreMethodName(initial: name)
		
		let substructureList = loadContainerBodyPart.substructures
		var argumentStack = ContainerPartBuilder.argumentInfo(substructures: substructureList, content: content)
		if argumentStack.isEmpty {
			argumentStack = parseArgumentList(body: body, substructureList: substructureList)
		}
		let location = Location(file: file, byteOffset: bodyOffset)
		
		return TokenBuilderInfo(functionName: functionName,
								invocationBody: body,
								tokenList: tokenList,
								substructureList: substructureList,
								bodyOffset: bodyOffset,
								currentPartName: currentPartName,
								argumentStack: argumentStack,
								location: location,
								parsingContext: parsingContext,
								content: content,
								file: file)
	}
	
	
	private func parseArgumentList(body: String, substructureList: [SourceKitStructure]) -> [ArgumentInfo] {
		// Variable injection could also be passed here "$0.a = $1".
		// It parses ok but we may got something with comma on right side of the assignment. Tagged injection, for example.
		// Last used because of first substructure can be further contiguous registration "c.register(...).injection(We are here)"
		guard !body.contains("=") else {
			return [ArgumentInfo(name: "_", value: body, structure: substructureList.last ?? [:])]
		}
		return body.split(separator: ",").compactMap(self.parseArgument)
	}
	
	
	private func parseArgument(argument: String.SubSequence) -> ArgumentInfo? {
		let parts = argument.split(separator: ":")
		var result: (outerName: String, innerName: String, value: String) = ("", "", "")
		if parts.count == 0 {
			return nil
		} else if parts.count == 1 {
			result.value = String(parts[0])
			result.outerName = "_"
		} else {
			result.value = String(parts[1])
			
			let nameParts = parts[0].split(separator: " ", omittingEmptySubsequences: true)
			if nameParts.count == 1 {
				result.innerName = String(nameParts[0])
				result.outerName = String(nameParts[0])
			} else if nameParts.count == 2 {
				result.innerName = String(nameParts[1])
				result.outerName = String(nameParts[0])
			}
		}
		return ArgumentInfo(name: result.outerName, value: result.value, structure: [:])
	}
	
	
	private func tryBuildToken(use info: TokenBuilderInfo) -> DIToken? {
		for tokenBuilder in allTokenBuilders {
			if let token = tokenBuilder.build(using: info) {
				return token
			}
		}
		return nil
	}
}