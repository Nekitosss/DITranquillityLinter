//
//  TestOuterUIKitMethodRegistration.swift
//  LintableProject
//
//  Created by Nikita Patskov on 16/10/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import UIKit

import DITranquillity

private class MyClass: UITableViewController {
}

private class ParsablePart: DIPart {
	
	static let container: DIContainer = {
		let cont = DIContainer()
		cont.register(MyClass.init(nibName:bundle:))
		return cont
	}()
	
	static func load(container: DIContainer) {
		
	}
}
