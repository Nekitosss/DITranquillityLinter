//
//  MainDIFramework.swift
//  LintableProject
//
//  Created by Nikita on 07/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import DITranquillity

final class MainDIPart: DIPart {
	
	static func load(container: DIContainer) {
		container.register{ ParentClass.MyPresenter<Float>.init(value: $0, by(tag: ViewController.self, on: $1)) }
	}
	
}

