//
//  ParsingContext.swift
//  AEXML
//
//  Created by Nikita Patskov on 16/10/2018.
//

import Foundation

final class ParsingContext {
	
	
	let fileContainer: FileContainer
	let collectedInfo: [String: Type]
	var cachedContainers: [String: ContainerPart] = [:]
	var errors: [GraphError] = []
	var currentContainerName = DIKeywords.container.rawValue
	
	init(container: FileContainer, collectedInfo: [String: Type]) {
		self.fileContainer = container
		self.collectedInfo = collectedInfo
	}
}
