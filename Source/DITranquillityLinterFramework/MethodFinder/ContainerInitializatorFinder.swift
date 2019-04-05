//
//  ContainerInitializatorFinder.swift
//  DITranquillityLinter
//
//  Created by Nikita on 16/09/2018.
//

import Foundation
import SourceKittenFramework

final class ContainerInitializatorFinder {
	
	private let parsingContext: ParsingContext
	
	init(parsingContext: ParsingContext) {
		self.parsingContext = parsingContext
	}
	
	/// Trying to find container initialization and parse dependency praph.
	func findContainerStructure() -> [ContainerPart] {
		TimeRecorder.start(event: .createTokens)
		defer { TimeRecorder.end(event: .createTokens) }
		
		return getProssibleContainerTypeHolders()
			.compactMap { type in
				self.parsingContext.fileContainer.getOrCreateFile(by: type.filePath).map {
					self.recursivelyFindContainerAndBuildGraph(list: type.substructure, file: $0)
				}
			}.flatMap { $0 }
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
	
	
	private func recursivelyFindContainerAndBuildGraph(list: [SourceKitStructure], file: File) -> [ContainerPart] {
		return list
			.enumerated()
			.filter { self.isContainerInitialization(structure: $1) }
			.compactMap { (containerInitIndex, structure) -> ContainerPart? in
				
				guard containerInitIndex >= 0 else { return nil }
				if containerInitIndex == 0 {
					// something like "var container: DIContainer!"
					// We cannot handle it yet
					let nameInfo = structure.getNameInfo()
					
					let location = Location(file: file, byteOffset: nameInfo?.offset)
					let error = GraphError(infoString: "Incorrect graph initialization. DIContainer should be filled", location: location)
					parsingContext.errors.append(error)
					return nil
					
				} else if containerInitIndex > 0 {
					// .init call should be after variable name declaration. So index should be greater than 0
					parsingContext.currentContainerName = list[containerInitIndex - 1].get(.name) ?? DIKeywords.container.rawValue
					return ContainerPart(substructureList: list, file: file, parsingContext: parsingContext, currentPartName: nil)
				} else {
					return nil
				}
				
			}
			+ list.flatMap { self.recursivelyFindContainerAndBuildGraph(list: $0.substructures, file: file) }
	}
	
	
	private func isContainerInitialization(structure: SourceKitStructure) -> Bool {
		let isDiContainerInitializerMethodName = structure.nameIs(DIKeywords.initDIContainer) || structure.nameIs(DIKeywords.diContainer)
		return isDiContainerInitializerMethodName && structure.isKind(of: SwiftExpressionKind.call)
	}
}
