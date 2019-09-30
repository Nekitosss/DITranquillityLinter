//
//  ContainerInitializatorFinder.swift
//  DITranquillityLinter
//
//  Created by Nikita on 16/09/2018.
//

import Foundation
import ASTVisitor

final class ContainerInitializatorFinder {
	
	private let parsingContext: GlobalParsingContext
	
	init(parsingContext: GlobalParsingContext) {
		self.parsingContext = parsingContext
	}
	
	/// Trying to find container initialization and parse dependency praph.
	func findContainerStructure(separatlyIncludePublicParts: Bool) -> [ContainerPart] {
		TimeRecorder.start(event: .createTokens)
		defer { TimeRecorder.end(event: .createTokens) }
		
		var intermediateResult: [ContainerIntermediatePart] = []
    var publiclyAvailableParts = Set<String>()
		for astFile in parsingContext.astFilePaths {
			do {
				let visitor = try Visitor(fileURL: URL(fileURLWithPath: astFile))
				visitor.visit(predicate: self.shouldHandle, visitChildNodesForFoundedPredicate: false) { node, parents in
					if let typealiasInfo = self.extractTypealias(node: node, parents: parents) {
						let name = typealiasInfo.name.droppedDotType().droppedDotProtocol()
						self.parsingContext.typealiasInfo[name] = typealiasInfo
					}
					
					if let containerPart = self.extractDIContainerCreation(node: node) {
						intermediateResult.append(containerPart)
					}
					if let diPartDeclaration = self.extractDIPartDeclaration(node: node) {
						self.parsingContext.parsedDIParts[diPartDeclaration.name] = diPartDeclaration.part
            if let accessToken = node[tokenKey: .access].getOne()?.value, accessToken == "public" || accessToken == "open" {
              publiclyAvailableParts.insert(diPartDeclaration.name)
            }
					}
				}
			} catch {
				fatalError(error.localizedDescription)
			}
		}
		
		let result = intermediateResult.map {
      ContainerPart(name: $0.name, tokenInfo: compose(diPartStack: [], currentPartName: $0.name, tokenList: $0.tokenInfo))
		}
    
    let publiclyAvailable = publiclyAvailableParts
      .compactMap { self.parsingContext.parsedDIParts[$0] }
      .map {
        ContainerPart(name: $0.name,
                      tokenInfo: compose(diPartStack: [],
                                         currentPartName: $0.name.map(changeToExactValue),
                                         tokenList: $0.tokenInfo))
    }
		
		return result + publiclyAvailable
	}
	
	private func extractTypealias(node: ASTNode, parents: [ASTNode]) -> TypealiasDeclaration? {
		guard
			node.kind == .typealiasDecl,
			let typealiasInfo = node.typedNode.unwrap(TypealiasDeclaration.self)
			else { return nil }
		return typealiasInfo
	}
	
  private func compose(diPartStack: [String], currentPartName: String?, tokenList: [DIToken]) -> [RegistrationAccessor: [RegistrationToken]] {
		let tokenListWithResolvedTypealiases = changeTypealaisesToExactValues(tokenList: tokenList)
		return tokenListWithResolvedTypealiases.reduce(into: [:]) { result, token in
			switch token {
			case .registration(let registration):
				registration.tokenList
					.compactMap { $0.underlyingValue as? AliasToken }
					.forEach { result[$0.getRegistrationAccessor(), default: []].append(registration) }
				
			case .append(let appendContainer):
				appendContainer.containerPart.tokenInfo
					.forEach { result[$0, default: []] += $1 }
				
			case .futureAppend(let futureContainer):
				guard let containerPart = self.parsingContext.parsedDIParts[futureContainer.typeName] else { return }
        
        var diPartStack = diPartStack
        if let partName = currentPartName {
          if diPartStack.contains(partName) {
            let message = "Invalid DIPart appending: \(diPartStack.joined(separator: ", ")) and trying to append \(partName) that already exists in append stack."
            let error = GraphError(infoString: message, location: futureContainer.location, kind: .circularPartAppending)
            self.parsingContext.errors.append(error)
            return
            
          } else if partName == futureContainer.typeName {
            let message = "Invalid DIPart appending: you are trying to append part to itself."
            let error = GraphError(infoString: message, location: futureContainer.location, kind: .circularPartAppending)
            self.parsingContext.errors.append(error)
            return
            
          } else {
            diPartStack.append(partName)
          }
        }
        
        compose(diPartStack: diPartStack, currentPartName: futureContainer.typeName, tokenList: containerPart.tokenInfo)
					.forEach { result[$0, default: []] += $1 }
				
			default:
				// Should not be here. All another tokens should be composed in registration and appendContainer tokens
				break
			}
		}
	}
	
	private func changeTypealaisesToExactValues(tokenList: [DIToken]) -> [DIToken] {
		return tokenList.map {
			switch $0 {
			case .registration(var token):
				token.typeName = changeToExactValue(typealiasName: token.typeName)
				token.plainTypeName = changeToExactValue(typealiasName: token.plainTypeName)
				token.tokenList = changeTypealaisesToExactValues(tokenList: token.tokenList)
				return token.diTokenValue
			case .injection(var token):
				token.typeName = changeToExactValue(typealiasName: token.typeName)
				token.plainTypeName = changeToExactValue(typealiasName: token.plainTypeName)
				return token.diTokenValue
			case .alias(var token):
				token.typeName = changeToExactValue(typealiasName: token.typeName)
				token.plainTypeName = changeToExactValue(typealiasName: token.plainTypeName)
				token.tag = changeToExactValue(typealiasName: token.tag)
				return token.diTokenValue
			case .futureAppend(var token):
				token.typeName = changeToExactValue(typealiasName: token.typeName)
				return token.diTokenValue
			case .append(var token):
				token.typeName = changeToExactValue(typealiasName: token.typeName)
				return token.diTokenValue
			case .isDefault:
				return $0
			}
		}
	}
	
	private func changeToExactValue(typealiasName: String) -> String {
		guard let typealiasValue = self.parsingContext.typealiasInfo[typealiasName] else { return typealiasName }
		return TypeName.onlyUnwrappedName(name: typealiasValue.sourceTypeName)
	}
	
	
	private func shouldHandle(node: ASTNode) -> Bool {
		return self.isDiContainerCreation(node: node)
			|| self.isDIPartMethod(node: node)
			|| self.isTypealiasDeclaration(node: node)
	}
	
	private func isDiContainerCreation(node: ASTNode) -> Bool {
		guard node.kind == .patternBindingDecl,
			let component = node[.patternTyped][.typeIdent][.component].getOne()?.typedNode.unwrap(Component.self),
			component.id == DIKeywords.diContainer.rawValue,
			component.bind == "DITranquillity.(file).DIContainer"
			else { return false }
		return true
	}
	
	private func isDIPartMethod(node: ASTNode) -> Bool {
		guard node.kind == .funcDecl,
			let rangeIndex = node.info.firstIndex(where: { $0.key == TokenKey.range.rawValue }), // Method name should be right after range info in AST
			let name = node.info[safe: rangeIndex + 1]?.value,
			name == DIKeywords.loadContainer.rawValue,
			node[.parameterList][.parameter].getOne()?[tokenKey: .type].getOne()?.value == DIKeywords.diContainer.rawValue
			else { return false }
		return true
	}
	
	private func isTypealiasDeclaration(node: ASTNode) -> Bool {
		return node.kind == .typealiasDecl
	}
	
	private func extractDIContainerCreation(node: ASTNode) -> ContainerIntermediatePart? {
		guard
			node.kind == .patternBindingDecl,
			let containerCreationNode = node[.callExpr][.closureExpr][.braceStmt].getOne(),
			let containerPart = self.buildContainerPart(list: containerCreationNode.children)
			else { return nil }
		return containerPart
	}
	
	private func extractDIPartDeclaration(node: ASTNode) -> (name: String, part: ContainerIntermediatePart)? {
		guard node.kind == .funcDecl,
			let containerPartName = node[.parameter].getOne()?[tokenKey: .type].getOne()?.value.droppedDotType()
			else { return nil }
		
		let containerPartCreationNode = node[.braceStmt].getOne() ?? node
		guard let containerPart = self.buildContainerPart(list: containerPartCreationNode.children)
			else { return nil }
		return (containerPartName, containerPart)
	}
	
	private func buildContainerPart(list: [ASTNode]) -> ContainerIntermediatePart? {
			return ContainerIntermediatePart(substructureList: list, parsingContext: parsingContext, containerParsingContext: ContainerParsingContext(), currentPartName: nil, diPartNameStack: [])
	}
}
