
import Foundation
import SourceKittenFramework

/// Trying to create AppendContainerToken
final class AppendContainerTokenBuilder: TokenBuilder {
	
	func build(using info: TokenBuilderInfo) -> DITokenConvertible? {
		guard
			info.functionName == DIKeywords.append.rawValue,
			let appendInfo = info.argumentStack.first,
			info.argumentStack.count == 1
			else { return nil }
		
		let typeName = appendInfo.value.droppedDotSelf()
		guard
			let swiftType = info.parsingContext.collectedInfo[typeName],
			self.isDIPart(appendInfo, swiftType: swiftType),
			let loadContainerStructure = swiftType.substructure.first(where: { $0.nameIs(DIKeywords.loadContainer) }),
			let newContainerPartFile = info.parsingContext.fileContainer.getOrCreateFile(by: swiftType.filePath)
			else { return nil }
		
		if info.diPartNameStack.contains(typeName) {
			// Handle circular DIPart append
			let appendDIChain = (info.diPartNameStack + [typeName]).joined(separator: " -> ")
			let error = GraphError(infoString: "Circular dependency: \(appendDIChain)", location: info.location, kind: .circularPartAppending)
			info.parsingContext.errors.append(error)
			return nil
		}
		
		let oldContainerName = info.parsingContext.currentContainerName
		info.parsingContext.currentContainerName = DIKeywords.container.rawValue
		let containerPart = ContainerPart(substructureList: loadContainerStructure.substructures,
										  file: newContainerPartFile,
										  parsingContext: info.parsingContext,
										  currentPartName: typeName,
										  diPartNameStack: info.diPartNameStack)
		info.parsingContext.currentContainerName = oldContainerName
		
		return AppendContainerToken(location: info.location, typeName: typeName, containerPart: containerPart)
	}
	
	private func isDIPart(_ argumentInfo: ArgumentInfo, swiftType: Type) -> Bool {
		return (argumentInfo.name == "part" && swiftType.inheritedTypes.contains(DIKeywords.diPart.rawValue))
			|| (argumentInfo.name == "framework" && swiftType.inheritedTypes.contains(DIKeywords.diFramework.rawValue))
	}
	
}
