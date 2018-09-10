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

class MyPresenterParent {
	
	var ss: String!
	
	init(stringValue str: String, _ intValue: Int) {
		
	}
}

class MyPresenter: MyPresenterParent, MyPresenterProtocol {
	
	func methodInjection(stringValue: String) {
		
	}
	
}
