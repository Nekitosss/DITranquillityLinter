//
//  ParsingContext.swift
//  AEXML
//
//  Created by Nikita Patskov on 16/10/2018.
//

import Foundation
import ASTVisitor

// Context in Command scope (single per command launch)
final class GlobalParsingContext {
	
	let astFilePaths: [String]
	var cachedContainers: [String: ContainerPart] = [:]
	var errors: [GraphError] = []
	var warnings: [GraphWarning] = []
	var currentContainerName = DIKeywords.container.rawValue
	var parsedDIParts: [String: ContainerIntermediatePart] = [:]
	var typealiasInfo: [String: TypealiasDeclaration] = [:]
	
	init(astFilePaths: [String]) {
		self.astFilePaths = astFilePaths
	}
}

// Context in Container initialization scope
final class ContainerParsingContext {
	var parsedParts: [String: [Location]] = [:]
}
