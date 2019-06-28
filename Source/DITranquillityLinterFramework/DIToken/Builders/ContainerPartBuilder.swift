//
//  ContainerPartBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/11/2018.
//


import SourceKittenFramework
import Foundation
import ASTVisitor

final class ContainerPartBuilder {
	
	static func argumentInfo(substructures: [SourceKitStructure], content: NSString) -> [ArgumentInfo] {
		return substructures.compactMap { structure in
			
			guard
				structure.isKind(of: SwiftExpressionKind.argument),
				let body = structure.body(using: content),
				let (nameOffset, nameLength) = structure.getNameInfo()
				else { return nil }
			let name = nameLength > 0 ? content.substringUsingByteRange(start: nameOffset, length: nameLength) ?? "_" : "_"
			return ArgumentInfo(name: name, value: body, structure: structure)
		}
	}
	
	
	private let parsingContext: GlobalParsingContext
	private let containerParsingContext: ContainerParsingContext
	private let currentPartName: String?
	private let diPartNameStack: [String]
	private let allTokenBuilders: [TokenBuilder]
	private let registrationTokenBuilder: RegistrationTokenBuilder
	
	
	init(parsingContext: GlobalParsingContext, containerParsingContext: ContainerParsingContext, currentPartName: String?, diPartNameStack: [String]) {
		self.parsingContext = parsingContext
		self.containerParsingContext = containerParsingContext
		self.currentPartName = currentPartName
		self.diPartNameStack = diPartNameStack
		self.registrationTokenBuilder = RegistrationTokenBuilder()
		self.allTokenBuilders = [AliasTokenBuilder(),
								 InjectionTokenBuilder(),
								 self.registrationTokenBuilder,
								 IsDefaultTokenBuilder(),
								 AppendContainerTokenBuilder()
		]
	}
	
	
	func build(substructureList: [ASTNode]) -> [RegistrationAccessor: [RegistrationToken]] {
		var intermediateTokenList: [DITokenConvertible] = []
		var assignedRegistrations: [String: RegistrationToken] = [:]
		var otherRegistrations: [DITokenConvertible] = []
		var nextAssignee: String?
		
		for substructure in substructureList {
			processRegistrationChain(substructure: substructure,
									 intermediateTokenList: &intermediateTokenList,
									 nextAssignee: &nextAssignee,
									 otherRegistrations: &otherRegistrations,
									 assignedRegistrations: &assignedRegistrations)
		}
		
		let assignedRegistrationValues = Array(assignedRegistrations.values)
		let tokenList = otherRegistrations + (assignedRegistrationValues as [DITokenConvertible])
		return compose(tokenList: tokenList)
	}
	
	
	private func processRegistrationChain(substructure: ASTNode, intermediateTokenList: inout [DITokenConvertible], nextAssignee: inout String?, otherRegistrations: inout [DITokenConvertible], assignedRegistrations: inout [String: RegistrationToken]) {
		intermediateTokenList.removeAll()
		let assignee = nextAssignee
		nextAssignee = nil
//		guard let kind: String = substructure.get(.kind) else {
//			return
//		}
		
		switch substructure.kind {
		case .callExpr:
			processExpressionKindCall(use: substructure, assignee: assignee, intermediateTokenList: &intermediateTokenList, otherRegistrations: &otherRegistrations, assignedRegistrations: &assignedRegistrations)
//		case SwiftDeclarationKind.varLocal.rawValue:
//			nextAssignee = processVarLocalDeclarationKind(use: substructure, otherRegistrations: &otherRegistrations, assignedRegistrations: assignedRegistrations)
//				?? nextAssignee
		default:
			break
		}
	}
	
	
	private func processExpressionKindCall(use substructure: ASTNode, assignee: String?, intermediateTokenList: inout [DITokenConvertible], otherRegistrations: inout [DITokenConvertible], assignedRegistrations: inout [String: RegistrationToken]) {
		// Get all tokens
		var collectedTokens = self.processLoadContainerBodyPart(loadContainerBodyPart: substructure, tokenList: &intermediateTokenList)
		
		if let registrationTokenIndex = collectedTokens.firstIndex(where: { $0 is RegistrationToken }) {
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
			
//		} else if let name: String = substructure.get(.name),
//			let firstDotIndex = name.firstIndex(of: "."),
//			let registrationToken = assignedRegistrations[String(name[..<firstDotIndex])] {
//			// something like:
//			// let r = container.register(_:)  (processed earlier)
//			// r.inject(_:)  (processed in that if block)
//			let inputTokenList =
//				registrationToken.tokenList.map { $0.underlyingValue }
//				+ collectedTokens
//				+ intermediateTokenList
//			let tokenList = self.registrationTokenBuilder.fillTokenListWithInfo(input: inputTokenList,
//																				registrationTypeName: registrationToken.plainTypeName,
//																				parsingContext: parsingContext,
//																				content: content,
//																				file: file)
//			let newToken = RegistrationToken(typeName: registrationToken.typeName,
//											 plainTypeName: registrationToken.plainTypeName,
//											 location: registrationToken.location,
//											 tokenList: tokenList.map { $0.diTokenValue })
//			assignedRegistrations[String(name[..<firstDotIndex])] = newToken
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
	private func processVarLocalDeclarationKind(use substructure: SourceKitStructure, otherRegistrations: inout [DITokenConvertible], assignedRegistrations: [String: RegistrationToken]) -> String? {
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
	
	
	private func compose(tokenList: [DITokenConvertible]) -> [RegistrationAccessor: [RegistrationToken]] {
		return tokenList.reduce(into: [:]) { result, token in
			switch token {
			case let registration as RegistrationToken:
				registration.tokenList
					.compactMap { $0.underlyingValue as? AliasToken }
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
	
	
	private func processLoadContainerBodyPart(loadContainerBodyPart: ASTNode, tokenList: inout [DITokenConvertible]) -> [DITokenConvertible] {
		guard let info = self.getTokenInfo(from: loadContainerBodyPart, tokenList: tokenList) else {
			return []
		}
		
		var result: [DITokenConvertible] = []
		if let token = tryBuildToken(use: info) {
			if token.diTokenValue.isIntermediate {
				tokenList.append(token)
			} else {
				tokenList.removeAll()
				result.append(token)
			}
		}
//		else if info.argumentStack.contains(where: { $0.value == parsingContext.currentContainerName }) {
//			let message = "You should use \(DIKeywords.diFramework.rawValue) or \(DIKeywords.diPart.rawValue) for injection purposes"
//			let invalidCallError = GraphError(infoString: message, location: info.location, kind: .parsing)
//			parsingContext.errors.append(invalidCallError)
//		}
		
		for substructure in loadContainerBodyPart.children {
			result += processLoadContainerBodyPart(loadContainerBodyPart: substructure, tokenList: &tokenList)
		}
		return result
	}
	
	
	private func getTokenInfo(from loadContainerBodyPart: ASTNode, tokenList: [DITokenConvertible]) -> TokenBuilderInfo? {
		guard loadContainerBodyPart.kind == .callExpr,
			let declRefNode = loadContainerBodyPart[.dotSyntaxCallExpr][.declrefExpr].getOne(),
			let declIndex = declRefNode.info.firstIndex(where: { $0.key == TokenKey.decl.rawValue }),
			declRefNode.info[declIndex].value == "DITranquillity.(file).DIComponentBuilder",
			let calledMethodName = declRefNode.info[safe: declIndex + 1]?.value
			else { return nil }
		return TokenBuilderInfo(functionName: calledMethodName,
								tokenList: tokenList,
								node: loadContainerBodyPart,
								currentPartName: self.currentPartName,
								parsingContext: self.parsingContext,
								containerParsingContext: self.containerParsingContext,
								diPartNameStack: self.diPartNameStack)
		
//		guard
//			loadContainerBodyPart.isKind(of: SwiftExpressionKind.call),
//			let name: String = loadContainerBodyPart.get(.name),
//			let bodyOffset = loadContainerBodyPart.getBodyInfo()?.offset,
//			let body = loadContainerBodyPart.body(using: content)
//			else { return nil }
//		let functionName = TypeFinder.restoreMethodName(initial: name)
//
//		let substructureList = loadContainerBodyPart.substructures
//		var argumentStack = ContainerPartBuilder.argumentInfo(substructures: substructureList, content: content)
//		if argumentStack.isEmpty {
//			argumentStack = parseArgumentList(body: body, substructureList: substructureList)
//		}
//		let location = Location(file: file, byteOffset: bodyOffset)
//
//		return TokenBuilderInfo(functionName: functionName,
//								invocationBody: body,
//								tokenList: tokenList,
//								substructureList: substructureList,
//								bodyOffset: bodyOffset,
//								currentPartName: currentPartName,
//								argumentStack: argumentStack,
//								location: location,
//								parsingContext: parsingContext,
//								containerParsingContext: containerParsingContext,
//								content: content,
//								file: file,
//								diPartNameStack: self.diPartNameStack)
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
	
	
	private func tryBuildToken(use info: TokenBuilderInfo) -> DITokenConvertible? {
		for tokenBuilder in allTokenBuilders {
			if let token = tokenBuilder.build(using: info) {
				return token
			}
		}
		return nil
	}
}
