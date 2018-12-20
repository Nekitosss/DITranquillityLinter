//
//  InjectionModificator.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 10/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

enum InjectionModificator {
	case tagged(String)
	case typed(String)
	case many
	
	
	static func isMany(_ modificators: [InjectionModificator]) -> Bool {
		for modificator in modificators {
			switch modificator {
			case .many:
				return true
			default:
				continue
			}
		}
		return false
	}
	
	static func forcedType(_ modificators: [InjectionModificator]) -> String? {
		for modificator in modificators {
			switch modificator {
			case .typed(let forcedType):
				return forcedType
			default:
				continue
			}
		}
		return nil
	}
}
