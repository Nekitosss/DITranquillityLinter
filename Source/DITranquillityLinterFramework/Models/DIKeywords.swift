//
//  DIKeywords.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 12.09.2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

enum DIKeywords: String {
	case initializerRegister = "extension.register(file:line:_:)"
	case typeRegister = "extension.register(_:file:line:)"
	case injection = "extension.injection(name:cycle:_:)"
    case modifiedInjection = "extension.injection(name:cycle:_:_:)"
	case `default` = "extension.default()"
	case `as` = "extension.as"
    case taggedAlias = "extension.as(check:tag:_:)"
	case check = "check"
	case tag = "tag"
	case by = "by"
	case many = "DITranquillity.(file).many"
	case cycle = "cycle"
	case loadContainer = "load(container:)"
	case diFramework = "DIFramework"
	case diPart = "DIPart"
	case append = "extension.append(part:)"
	case diContainer = "DIContainer"
	case initDIContainer = "DIContainer.init"
	case appDelegate = "AppDelegate"
	case container = "container"
	case xcTestCase = "XCTestCase"
	case part = "part"
	case framework = "framework"
}
