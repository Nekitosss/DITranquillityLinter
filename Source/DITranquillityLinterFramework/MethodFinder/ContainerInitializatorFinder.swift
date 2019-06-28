//
//  ContainerInitializatorFinder.swift
//  DITranquillityLinter
//
//  Created by Nikita on 16/09/2018.
//

import Foundation
import SourceKittenFramework
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
		
		var result: [ContainerPart] = []
		for astFile in parsingContext.astFilePaths {
			do {
				let visitor = try Visitor(fileURL: URL(fileURLWithPath: astFile))
				visitor.visit(predicate: self.shouldHandle, visitChildNodesForFoundedPredicate: false) { node, _ in
					if let containerPart = self.extractDIContainerCreation(node: node) {
						result.append(containerPart)
					}
					if let diPartDeclaration = self.extractDIPartDeclaration(node: node) {
						self.parsingContext.cachedContainers[diPartDeclaration.name] = diPartDeclaration.part
					}
				}
			} catch {
				fatalError(error.localizedDescription)
			}
		}
		
		return result
	}
	
	private func shouldHandle(node: ASTNode) -> Bool {
		return self.isDiContainerCreation(node: node) || self.isDIPartMethod(node: node)
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
			node[.parameterList][.parameter].getOne()?[tokenKey: .type]?.value == DIKeywords.diContainer.rawValue
			else { return false }
		return true
	}
	
	private func extractDIContainerCreation(node: ASTNode) -> ContainerPart? {
		guard
			node.kind == .patternBindingDecl,
			let containerCreationNode = node[.callExpr][.closureExpr][.braceStmt].getOne(),
			let containerPart = self.buildContainerPart(list: containerCreationNode.children)
			else { return nil }
		return containerPart
	}
	
	private func extractDIPartDeclaration(node: ASTNode) -> (name: String, part: ContainerPart)? {
		guard node.kind == .funcDecl,
			let containerPartName = node[.parameter].getOne()?[tokenKey: .type]?.value.droppedDotType(),
			let containerPartCreationNode = node[.braceStmt].getOne(),
			let containerPart = self.buildContainerPart(list: containerPartCreationNode.children)
			else { return nil }
		return (containerPartName, containerPart)
	}
	
	private func getProssibleContainerTypeHolders() -> [Type] {
		var possibleContainerValues = parsingContext.collectedInfo.values.filter {
			$0.inheritedTypes.contains(DIKeywords.diPart.rawValue)
				|| $0.inheritedTypes.contains(DIKeywords.diFramework.rawValue)
				|| $0.inheritedTypes.contains(DIKeywords.xcTestCase.rawValue)
		}
		if let appDelegateClass = parsingContext.collectedInfo[DIKeywords.appDelegate.rawValue] {
			possibleContainerValues.insert(appDelegateClass, at: 0)
		}
		return possibleContainerValues
	}
	
	
//	private func recursivelyFindContainerAndBuildGraph(list: [SourceKitStructure], file: File) -> [ContainerPart] {
//		return list
//			.enumerated()
//			.filter { self.isContainerInitialization(structure: $1) }
//			.compactMap { self.buildContainerPart(containerInitIndex: $0, structure: $1, file: file, list: list) }
//			+ list.flatMap { self.recursivelyFindContainerAndBuildGraph(list: $0.substructures, file: file) }
//	}
	
	private func buildContainerPart(list: [ASTNode]) -> ContainerPart? {
//		if containerInitIndex == 0 {
//			// something like "var container: DIContainer!"
//			// We cannot handle it yet
//			let nameInfo = structure.getNameInfo()
//
//			let location = Location(file: file, byteOffset: nameInfo?.offset)
//			let error = GraphError(infoString: "Incorrect graph initialization. DIContainer should be filled", location: location, kind: .parsing)
//			parsingContext.errors.append(error)
//			return nil
//
//		} else if containerInitIndex > 0 {
			// .init call should be after variable name declaration. So index should be greater than 0
//			parsingContext.currentContainerName = list[containerInitIndex - 1].get(.name) ?? DIKeywords.container.rawValue
			return ContainerPart(substructureList: list, parsingContext: parsingContext, containerParsingContext: ContainerParsingContext(), currentPartName: nil, diPartNameStack: [])
//		} else {
//			return nil
//		}
	}
	
	private func isContainerInitialization(structure: SourceKitStructure) -> Bool {
		let isDiContainerInitializerMethodName = structure.nameIs(DIKeywords.initDIContainer) || structure.nameIs(DIKeywords.diContainer)
		return isDiContainerInitializerMethodName && structure.isKind(of: SwiftExpressionKind.call)
	}
	
	private func extractPublicDIPart(type: Type, file: File, parsingContext: GlobalParsingContext) -> [ContainerPart] {
		guard type.isPubliclyAvailable else {
			return []
		}
		return []
//		let loadContainerSubstructure = type.substructure
//			.filter { $0.get(.name) == "load(container:)" }
//			.flatMap { $0.substructures }
//
//		return [ContainerPart(substructureList: loadContainerSubstructure, file: file, parsingContext: parsingContext, containerParsingContext: ContainerParsingContext(), currentPartName: type.name, diPartNameStack: [])]
	}
}
