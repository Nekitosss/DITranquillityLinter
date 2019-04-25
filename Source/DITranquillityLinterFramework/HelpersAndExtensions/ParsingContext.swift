//
//  ParsingContext.swift
//  AEXML
//
//  Created by Nikita Patskov on 16/10/2018.
//

import Foundation

// Context in Command scope (single per command launch)
final class GlobalParsingContext {
	
	let fileContainer: FileContainer
	let collectedInfo: [String: Type]
	var cachedContainers: [String: ContainerPart] = [:]
	var errors: [GraphError] = []
	var warnings: [GraphWarning] = []
	var currentContainerName = DIKeywords.container.rawValue
	
	init(container: FileContainer, collectedInfo: [String: Type]) {
		self.fileContainer = container
		self.collectedInfo = collectedInfo
	}
}

// Context in Container initialization scope
final class ContainerParsingContext {
	var parsedParts: [String: [Location]] = [:]
}
