
import Foundation
import ASTVisitor

/// Trying to create AppendContainerToken
final class AppendContainerTokenBuilder: TokenBuilder {
	
	func build(using info: TokenBuilderInfo) -> DITokenConvertible? {
		
		guard
			info.functionName == DIKeywords.append.rawValue,
			let declrefExpr = info.node[.dotSyntaxCallExpr][.declrefExpr].getOne()?.typedNode.unwrap(DeclrefExpression.self),
			let astLocation = declrefExpr.location,
			let appendedType = info.node[.tupleExpr][.erasureExpr][.dotSelfExpr][.typeExpr].getOne()?[tokenKey: .typerepr].getOne()?.value
			else { return nil }
		let location = Location(visitorLocation: astLocation)
		if let containerPart = info.parsingContext.cachedContainers[appendedType] {
			return AppendContainerToken(location: location, typeName: appendedType, containerPart: containerPart)
		} else {
			return FutureAppendContainerToken(location: location, typeName: appendedType)
		}
		
//		let typeName = appendInfo.value.droppedDotSelf()
//
//		if info.diPartNameStack.contains(typeName) {
//			// Handle circular DIPart append
//			let appendDIChain = (info.diPartNameStack + [typeName]).joined(separator: " -> ")
//			let error = GraphError(infoString: "Circular dependency: \(appendDIChain)", location: info.location, kind: .circularPartAppending)
//			info.parsingContext.errors.append(error)
//			return nil
//		}
//
//		guard let containerPart =
//			self.tryParseContainerPartInCurrentModule(info: info, appendInfo: appendInfo, typeName: typeName)
//			?? info.parsingContext.cachedContainers[typeName]
//			else { return nil }
//
//		guard validateAlreadyAppendedPartToThisContainer(info: info, typeName: typeName) else {
//			return nil
//		}
		
		
	}
	
//	private func tryParseContainerPartInCurrentModule(info: TokenBuilderInfo, appendInfo: ArgumentInfo, typeName: String) -> ContainerPart? {
//		guard
//			let swiftType = info.parsingContext.collectedInfo[typeName],
//			self.isDIPart(appendInfo, swiftType: swiftType),
//			let loadContainerStructure = swiftType.substructure.first(where: { $0.nameIs(DIKeywords.loadContainer) }),
//			let newContainerPartFile = info.parsingContext.fileContainer.getOrCreateFile(by: swiftType.filePath)
//			else { return nil }
//		return nil
////		let oldContainerName = info.parsingContext.currentContainerName
////		info.parsingContext.currentContainerName = DIKeywords.container.rawValue
////		let containerPart = ContainerPart(substructureList: loadContainerStructure.substructures,
////										  file: newContainerPartFile,
////										  parsingContext: info.parsingContext,
////										  containerParsingContext: info.containerParsingContext,
////										  currentPartName: typeName,
////										  diPartNameStack: info.diPartNameStack)
////		info.parsingContext.currentContainerName = oldContainerName
////		return containerPart
//	}
//
//	private func isDIPart(_ argumentInfo: ArgumentInfo, swiftType: Type) -> Bool {
//		return (argumentInfo.name == DIKeywords.part.rawValue && swiftType.inheritedTypes.contains(DIKeywords.diPart.rawValue))
//			|| (argumentInfo.name == DIKeywords.framework.rawValue && swiftType.inheritedTypes.contains(DIKeywords.diFramework.rawValue))
//	}
//	
//	private func validateAlreadyAppendedPartToThisContainer(info: TokenBuilderInfo, typeName: String) -> Bool {
//		if var previousParsedLocations = info.containerParsingContext.parsedParts[typeName] {
//			previousParsedLocations.append(info.location)
//			info.containerParsingContext.parsedParts[typeName] = previousParsedLocations
//			let warning = GraphWarning(infoString: "\(typeName) was already included to container", location: info.location)
//			info.parsingContext.warnings.append(warning)
//			return false
//		} else {
//			info.containerParsingContext.parsedParts[typeName] = [info.location]
//			return true
//		}
//	}
	
}
