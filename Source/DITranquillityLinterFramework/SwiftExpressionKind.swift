//
//  SwiftExpressionKind.swift
//  DITranquillityLinterFramework
//
//  Created by Nikita on 03/09/2018.
//  Copyright © 2018 Nikita. All rights reserved.
//

import Foundation

enum SwiftExpressionKind: String {
	case call = "source.lang.swift.expr.call"
	case argument = "source.lang.swift.expr.argument"
	case array = "source.lang.swift.expr.array"
	case dictionary = "source.lang.swift.expr.dictionary"
	case objectLiteral = "source.lang.swift.expr.object_literal"
	case closure = "source.lang.swift.expr.closure"
}
