


import Foundation


final class ImplicitFrameworkDependencyTypesResolver {
	
	private let binaryFrameworkParser: BinaryFrameworkParser
	
	init(binaryFrameworkParser: BinaryFrameworkParser) {
		self.binaryFrameworkParser = binaryFrameworkParser
	}
	
	func resolveTypesFromImplicitDependentBinaryFrameworks(in allTypes: [Type], composedTypes: [String: Type]) throws -> [FileParserResult]? {
		let resolvedTypes = Set(composedTypes.keys)
		let unresolvedTypes: Set<String> = allTypes.reduce(into: []) {
			$0.formUnion(findUnresolvedTypes(in: $1, resolvedTypes: resolvedTypes))
		}
		return try self.binaryFrameworkParser.parseBinaryModules(names: unresolvedTypes)
	}
	
	private func findUnresolvedTypes(in type: Type, resolvedTypes: Set<String>) -> Set<String> {
		var allContainedTypes: Set<String> = []
		allContainedTypes.formUnion(type.inheritedTypes)
		// Should we allow plain UIKit types injection?
		// Inheritance requirement will be a lot faster
		// If we will choose allow plain UIKit injection, implement for [MyType]. Currently not implemented here.
//		allContainedTypes.formUnion(type.variables.map({ $0.typeName.unwrappedTypeName }))
//		allContainedTypes.formUnion(type.methods.flatMap({ $0.parameters.map({ $0.typeName.unwrappedTypeName }) }))
		
		return allContainedTypes.subtracting(resolvedTypes)
	}
	
}
