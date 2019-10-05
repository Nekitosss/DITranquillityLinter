//
//  TestError.swift
//  DITranquillityLinterTests
//
//  Created by Nikita Patskov on 02/10/2018.
//

enum TestError: String, Error {
	case containerInfoNotFound
	case registrationTokenNotFound
	case injectionTokenNotFound
	case aliasTokenNotFound
}
