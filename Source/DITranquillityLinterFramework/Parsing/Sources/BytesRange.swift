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

    // sourcery:inline:BytesRange.AutoCoding
        /// :nodoc:
        required init?(coder aDecoder: NSCoder) {
            self.offset = aDecoder.decodeInt64(forKey: "offset")
            self.length = aDecoder.decodeInt64(forKey: "length")
        }

        /// :nodoc:
        func encode(with aCoder: NSCoder) {
            aCoder.encode(self.offset, forKey: "offset")
            aCoder.encode(self.length, forKey: "length")
        }
    // sourcery:end
}
