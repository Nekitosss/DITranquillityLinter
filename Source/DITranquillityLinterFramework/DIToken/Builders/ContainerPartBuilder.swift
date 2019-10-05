//
//  ContainerPartBuilder.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 22/11/2018.
//


import Foundation
import ASTVisitor

final class ContainerPartBuilder {

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
	
	
	func build(substructureList: [ASTNode]) -> [DITokenConvertible] {
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
		return otherRegistrations + (assignedRegistrationValues as [DITokenConvertible])
	}
	
	
	private func processRegistrationChain(substructure: ASTNode, intermediateTokenList: inout [DITokenConvertible], nextAssignee: inout String?, otherRegistrations: inout [DITokenConvertible], assignedRegistrations: inout [String: RegistrationToken]) {
		intermediateTokenList.removeAll()
		let assignee = nextAssignee
		nextAssignee = nil
		
		switch substructure.kind {
		case .callExpr:
			processExpressionKindCall(use: substructure, assignee: assignee, intermediateTokenList: &intermediateTokenList, otherRegistrations: &otherRegistrations, assignedRegistrations: &assignedRegistrations)
			
		case .patternBindingDecl:
			// For handling:
			// var r = container.register(_:)
			// r.injectSomething...
			// r = container.register(_:)
			guard let name = substructure[.patternNamed].getOne()?.info.last?.value,
				let callExpr = substructure[.callExpr].getOne()
				else { return }
			if let registration = assignedRegistrations[name] {
				otherRegistrations.append(registration)
			}
			processExpressionKindCall(use: callExpr, assignee: name, intermediateTokenList: &intermediateTokenList, otherRegistrations: &otherRegistrations, assignedRegistrations: &assignedRegistrations)
			
		default:
			break
		}
	}
	
	
	private func processExpressionKindCall(use substructure: ASTNode, assignee: String?, intermediateTokenList: inout [DITokenConvertible], otherRegistrations: inout [DITokenConvertible], assignedRegistrations: inout [String: RegistrationToken]) {
		
		// Assume that: let r = container.register(...)
		// "r" - stored in assignee. Cause we assign registration to "r" variable
		// "container" - stored in callee. Cause we call "register" on "container"
		// Created for resolving: let r = c.register(...); r.alias(...);
		// TODO: Test r = r.alias(...)
		
		var callee: String?
		// Get all tokens
		var collectedTokens = self.processLoadContainerBodyPart(loadContainerBodyPart: substructure, tokenList: &intermediateTokenList, callee: &callee)
		
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
			
		} else {
			if let callee = callee, assignedRegistrations[callee] != nil {
				assignedRegistrations[callee]?.tokenList +=
					(collectedTokens + intermediateTokenList).map({ $0.diTokenValue })
			} else {
				// container.append(part:) for example
				otherRegistrations.append(contentsOf: collectedTokens)
			}
		}
	}
	
	
	private func processLoadContainerBodyPart(loadContainerBodyPart: ASTNode, tokenList: inout [DITokenConvertible], callee: inout String?) -> [DITokenConvertible] {
		var result: [DITokenConvertible] = []
		
		if let info = self.getTokenInfo(from: loadContainerBodyPart, tokenList: tokenList) {
			if let token = tryBuildToken(use: info) {
				if token.diTokenValue.isIntermediate {
					tokenList.append(token)
				} else {
					tokenList.removeAll()
					result.append(token)
				}
			}
			if
				let possibleCallee = loadContainerBodyPart[.dotSyntaxCallExpr][.declrefExpr].getSeveral()?.last,
				let declIndex = possibleCallee.info.firstIndex(where: { $0.key == TokenKey.decl.rawValue }),
				!isDIDeclarationValue(decl: possibleCallee.info[declIndex].value), // NOT!
				let calleeRange = possibleCallee.info[declIndex].value.range(of: "Name.\\(file\\).[a-zA-Z\\d_-]+.load\\(container:\\).[a-zA-Z\\d_-]+@", options: .regularExpression) {
					let fullCallee = possibleCallee.info[declIndex].value[calleeRange]
					let rawCallee = fullCallee.split(separator: ".").last?.dropLast()
					callee = rawCallee.map { String($0) }
      }
		}
    
    if let dotSyntaxCall = loadContainerBodyPart[.dotSyntaxCallExpr].getOne(), let anotherMethodCall = dotSyntaxCall[tokenKey: .type].getOne()?.value {
      
      let regexp = "DIContainer"
      if anotherMethodCall.range(of: regexp, options: .regularExpression) != nil {
        let message = "You should use \(DIKeywords.diFramework.rawValue) or \(DIKeywords.diPart.rawValue) for injection purposes"
        let astLocation = dotSyntaxCall.typedNode.unwrap(DotSyntaxCall.self)?.location
        let location = astLocation.map(Location.init(visitorLocation:)) ?? Location(file: nil)
        let invalidCallError = GraphError(infoString: message,
                                          location: location,
                                          kind: .parsing)
        parsingContext.errors.append(invalidCallError)
      }
    }
		
		for substructure in loadContainerBodyPart.children {
			result += processLoadContainerBodyPart(loadContainerBodyPart: substructure, tokenList: &tokenList, callee: &callee)
		}
		return result
	}
	
	
	private func getTokenInfo(from loadContainerBodyPart: ASTNode, tokenList: [DITokenConvertible]) -> TokenBuilderInfo? {
		guard loadContainerBodyPart.kind == .callExpr,
			let declRefNode = loadContainerBodyPart[.dotSyntaxCallExpr][.declrefExpr].getSeveral()?.first, // Todo add validation on second token
			let declIndex = declRefNode.info.firstIndex(where: { $0.key == TokenKey.decl.rawValue }),
			isDIDeclarationValue(decl: declRefNode.info[declIndex].value),
			let calledMethodName = declRefNode.info[safe: declIndex + 1]?.value
			else { return nil }
		return TokenBuilderInfo(functionName: calledMethodName,
								tokenList: tokenList,
								node: loadContainerBodyPart,
								currentPartName: self.currentPartName,
								parsingContext: self.parsingContext,
								containerParsingContext: self.containerParsingContext,
								diPartNameStack: self.diPartNameStack)
	}
	
	// Should refer to builder or container
	private func isDIDeclarationValue(decl: String) -> Bool {
		return decl == "DITranquillity.(file).DIComponentBuilder" || decl == "DITranquillity.(file).DIContainer"
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
