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
  case checkedAlias = "extension.as(check:_:)"
	case check = "check"
	case tag = "tag"
	case by = "by"
	case many = "DITranquillity.(file).many"
	case cycle = "cycle"
	case loadContainer = "load(container:)"
	case diFramework = "DIFramework"
	case diPart = "DIPart"
	case appendPart = "extension.append(part:)"
	case appendFramework = "extension.append(framework:)"
	case diContainer = "DIContainer"
	case initDIContainer = "DIContainer.init"
	case appDelegate = "AppDelegate"
	case container = "container"
	case xcTestCase = "XCTestCase"
	case part = "part"
	case framework = "framework"
	case diByTag = "DIByTag"
	case diMany = "DIMany"
}
