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
		
		container.register(ViewController.self)
			.as(UIViewController.self)
			.injection(\ViewController.presenter)
			.injection(\.presenter)
			.injection { $0.presenter = $1 }
			.injection { $0.presenter = $1 as MyPresenter }
		
	}
	
}

