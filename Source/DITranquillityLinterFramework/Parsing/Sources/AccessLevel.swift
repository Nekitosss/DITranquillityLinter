//
// Created by Krzysztof Zablocki on 13/09/2016.
// Copyright (c) 2016 Pixle. All rights reserved.
//

import Foundation

/// :nodoc:
enum AccessLevel: String, Codable, Equatable {
    case `internal` = "internal"
    case `private` = "private"
    case `fileprivate` = "fileprivate"
    case `public` = "public"
    case `open` = "open"
    case none = ""
}
