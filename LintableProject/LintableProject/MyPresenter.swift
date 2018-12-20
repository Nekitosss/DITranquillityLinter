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

protocol NotConformingPresenterProtocol {
	
}

protocol AnyProtocol {}

extension Float: AnyProtocol {
	
}

class ParentClass {
	
	class AndAnotherClass {
		
	}
	
	class MyPresenterParent<T: AnyProtocol> {
		
		var ss: String!
		
		init(value: T, _ another: AndAnotherClass) {
			
		}
	}
	
	class MyPresenter<T: AnyProtocol>: MyPresenterParent<T>, MyPresenterProtocol {
		
		func methodInjection(stringValue: String) {
			
		}
		
	}
}
