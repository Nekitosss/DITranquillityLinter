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
		
		container.register1 {
			MyPresenter(stringValue: $0 as String,
						55)
			
			}
			.as(MyPresenterProtocol.self)
			.injection { $0.methodInjection(stringValue: $1) }
			.injection { $0.ss = $1 as String }
		
		container.append(part: MainDIPart.self)
	}
	
}

