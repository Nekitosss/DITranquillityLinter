//
//  MyPresenter.swift
//  LintableProject
//
//  Created by Nikita on 07/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

protocol MyPresenterProtocol {
	
}

protocol AnyProtocol {}

extension Float: AnyProtocol {
	
}

class MyPresenterParent<T: AnyProtocol> {
	
	var ss: String!
	
	init(value: T, _ intValue: Int) {
		
	}
}

class MyPresenter<T: AnyProtocol>: MyPresenterParent<T>, MyPresenterProtocol {
	
	func methodInjection(stringValue: String) {
		
	}
	
}
