
//
//  File.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita Patskov on 01/10/2018.
//


/// For information about default component. c.register(...).default()
struct IsDefaultToken: DIToken {
	
	var isIntermediate: Bool {
		return true
	}
}
