//
//  MethodSignature.swift
//  DITranquillityLinter
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

struct MethodSignature {
	let name: String
	let injectableArgumentInfo: [(argumentCount: Int, argumentBodyOffset: Int64)]
	let injectionModificators: [Int: [InjectionModificator]]
}
