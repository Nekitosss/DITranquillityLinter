//
//  Created by Sébastien Duperron on 03/01/2018.
//  Copyright © 2018 Pixle. All rights reserved.
//

import Foundation

/// :nodoc:
@objcMembers final class BytesRange: NSObject, SourceryModel, Codable {

    let offset: Int64
    let length: Int64

    init(offset: Int64, length: Int64) {
        self.offset = offset
        self.length = length
    }

    convenience init(range: (offset: Int64, length: Int64)) {
        self.init(offset: range.offset, length: range.length)
    }

}
