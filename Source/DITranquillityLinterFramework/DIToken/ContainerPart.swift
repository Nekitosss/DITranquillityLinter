//
//  ContainerPart.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation
import SourceKittenFramework


// DIPart, DIFramework
final class ContainerPart {
	
	let tokenList: [DIToken]
	
	init(loadContainerStructure: [String : SourceKitRepresentable], file: File, collectedInfo: [String: SwiftType]) {
		let content = file.contents.bridge()
		let substructureList = loadContainerStructure.substructures ?? []
		var result: [RegistrationToken] = []
		var tokenList: [DIToken] = []
		for substructure in substructureList {
			ContainerPart.processLoadContainerBodyPart(loadContainerBodyPart: substructure, file: file, content: content, collectedInfo: collectedInfo, result: &result, tokenList: &tokenList)
		}
	
		self.tokenList = tokenList
	}
	
	private static func processLoadContainerBodyPart(loadContainerBodyPart: [String : SourceKitRepresentable], file: File, content: NSString, collectedInfo: [String: SwiftType], result: inout [RegistrationToken], tokenList: inout [DIToken]) {
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
			} else if let injection = InjectionToken(functionName: actualName, invocationBody: body, argumentStack: argumentStack, bodyOffset: bodyOffset, file: file) {
				tokenList.append(injection)
			} else if let registration = RegistrationToken(functionName: actualName, invocationBody: body, argumentStack: argumentStack, tokenList: tokenList, collectedInfo: collectedInfo, substructureList: substructureList, content: content, bodyOffset: bodyOffset, file: file) {
				tokenList.removeAll()
				result.append(registration)
			}
			
			for substructure in substructureList {
				processLoadContainerBodyPart(loadContainerBodyPart: substructure, file: file, content: content, collectedInfo: collectedInfo, result: &result, tokenList: &tokenList)
			}
			
		default:
			break
		}
	}
	
	static func argumentInfo(substructures: [[String: SourceKitRepresentable]], content: NSString) -> [ArgumentInfo] {
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
