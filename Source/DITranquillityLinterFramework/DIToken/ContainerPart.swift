//
//  ContainerPart.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework
import xcodeproj


// DIPart, DIFramework
final class ContainerPart {
	
	let tokenList: [DIToken]
	
	init(substructureList: [SourceKitStructure], file: File, collectedInfo: [String: Type], currentPartName: String?) {
		let content = file.contents.bridge()
		var result: [DIToken] = []
		var tmpTokenList: [DIToken] = []
		for substructure in substructureList {
			ContainerPart.processLoadContainerBodyPart(loadContainerBodyPart: substructure, file: file, content: content, collectedInfo: collectedInfo, result: &result, tokenList: &tmpTokenList, currentPartName: currentPartName)
		}
	
		self.tokenList = result
	}
	
	private static func processLoadContainerBodyPart(loadContainerBodyPart: [String : SourceKitRepresentable], file: File, content: NSString, collectedInfo: [String: Type], result: inout [DIToken], tokenList: inout [DIToken], currentPartName: String?) {
		guard let kind: String = loadContainerBodyPart.get(.kind) else { return }
		
		switch kind {
		case SwiftExpressionKind.call.rawValue:
			guard let name: String = loadContainerBodyPart.get(.name),
				let bodyOffset: Int64 = loadContainerBodyPart.get(.bodyOffset),
				let bodyLength: Int64 = loadContainerBodyPart.get(.bodyLength)
				else { return }
			let body = content.substringUsingByteRange(start: bodyOffset, length: bodyLength)!
			let actualName = extractActualFuncionInvokation(name: name)
			
			let substructureList = loadContainerBodyPart.substructures ?? []
			let argumentStack = argumentInfo(substructures: substructureList, content: content)
			
			if let alias = AliasToken(functionName: actualName, invocationBody: body, argumentStack: argumentStack, bodyOffset: bodyOffset, file: file) {
				tokenList.append(alias)
			} else if let injection = InjectionToken(functionName: actualName, invocationBody: body, argumentStack: argumentStack, bodyOffset: bodyOffset, file: file, substructureList: substructureList) {
				tokenList.append(injection)
			} else if let registration = RegistrationToken(functionName: actualName, invocationBody: body, argumentStack: argumentStack, tokenList: tokenList, collectedInfo: collectedInfo, substructureList: substructureList, content: content, bodyOffset: bodyOffset, file: file) {
				tokenList.removeAll()
				result.append(registration)
			} else if let appendContainerToken = AppendContainerToken(functionName: actualName, invocationBody: body, collectedInfo: collectedInfo, argumentStack: argumentStack, bodyOffset: bodyOffset, file: file, currentPartName: currentPartName) {
				result.append(appendContainerToken)
			}
			
			for substructure in substructureList {
				processLoadContainerBodyPart(loadContainerBodyPart: substructure, file: file, content: content, collectedInfo: collectedInfo, result: &result, tokenList: &tokenList, currentPartName: currentPartName)
			}
			
		default:
			break
		}
	}
	
	static func argumentInfo(substructures: [SourceKitStructure], content: NSString) -> [ArgumentInfo] {
		var argumentStack = [ArgumentInfo]()
		let substructures = substructures.filter({ $0.get(.kind, of: String.self) == SwiftExpressionKind.argument.rawValue })
		
		for structure in substructures {
			guard let bodyOffset: Int64 = structure.get(.bodyOffset),
				let bodyLength: Int64 = structure.get(.bodyLength),
				let nameLength: Int64 = structure.get(.nameLength),
				let nameOffset: Int64 = structure.get(.nameOffset)
				else { continue }
			let body = content.substringUsingByteRange(start: bodyOffset, length: bodyLength) ?? ""
			let name = nameLength > 0 ? content.substringUsingByteRange(start: nameOffset, length: nameLength) ?? "" : ""
			let argument = ArgumentInfo(name: name, value: body, structure: structure)
			argumentStack.append(argument)
		}
		return argumentStack
	}
	
	static func extractActualFuncionInvokation(name: String) -> String {
		guard let dotIndex = name.reversed().index(of: ".") else {
			return name
		}
		return String(name[dotIndex.base...])
	}
	
}
