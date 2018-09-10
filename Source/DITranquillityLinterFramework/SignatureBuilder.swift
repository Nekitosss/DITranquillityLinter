//
//  SignatureBuilder.swift
//  DITranquillityLinter
//
//  Created by Nikita on 10/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

struct MethodSignature {
	let name: String
	let injectableArgumentNumbers: [Int]
	let injectionModificators: [Int: [InjectionModificator]]
}

final class SignatureBuilder {
	
	func buildSignature(body: String) -> MethodSignature? {
		guard !body.isEmpty else { return nil }
		guard let oldArgumentBodyStartIndex = body.index(of: "(") else { return nil }
		var dotStringIndex: String.Index?
		var index = body.startIndex
		var body = body
		while index != body.endIndex {
			index = body.index(after: index)
			if body[index] == "." {
				dotStringIndex = index
			} else if body[index] == "(" {
				break
			}
		}
		if dotStringIndex == nil || body.index(before: oldArgumentBodyStartIndex) == dotStringIndex {
			body.insert(contentsOf: ".init", at: body.index(before: oldArgumentBodyStartIndex))
		}
		guard let argumentBodyStartIndex = body.index(of: "("),
			let argumentBodyEndIndex = body.reversed().index(of: ")")?.base
			else { return nil }
		let argumentBody = String(body[body.index(after: argumentBodyStartIndex) ..< argumentBodyEndIndex])
		let argumentInfoList = AliasToken.parseArgumentList(body: argumentBody)
		let methodName = body[body.index(after: dotStringIndex ?? body.startIndex) ..< argumentBodyStartIndex]
		var methodSignature = String(methodName + "(")
		var injectableArgumentNumbers: [Int] = []
		for (argumentIndex, argumentInfo) in argumentInfoList.enumerated() {
			methodSignature += argumentInfo.name
			if argumentIndex != argumentInfoList.count {
				methodSignature += ":"
			}
			if isInjection(name: argumentInfo.value) {
				injectableArgumentNumbers.append(argumentIndex)
			}
		}
		methodSignature += ")"
		return MethodSignature(name: methodSignature, injectableArgumentNumbers: injectableArgumentNumbers, injectionModificators: [:])
	}
	
	private func isInjection(name: String) -> Bool {
		return name.firstMatch("\\$[0-9][0-9]?") != nil
	}
	
}
