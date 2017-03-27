import Foundation

struct CARHeader {
    private let magic = "RATC"
    private let coreUIVersion = 372
    private let storageVersion = 10
    private let renditionCount: Int
    private let program = "@(#)PROGRAM:com.asynchrony.ReLax"
    private let version = "com.asynchrony.ReLax-1.0"
    private let uuid = uuidData()
    private let checksum = 0
    private let schemaVersion = 5
    private let colorSpaceID = 1
    private let keySemantics = 1
    
    init(renditionCount: Int) {
        self.renditionCount = renditionCount
    }
    
    func data() -> Data {
        return concatData([magic.data(using: .ascii)!, int32Data(coreUIVersion), int32Data(storageVersion), zeroPadding(4), int32Data(renditionCount), program.padded(count: 128), version.padded(count: 256), uuid, int32Data(checksum), int32Data(schemaVersion), int32Data(colorSpaceID), int32Data(keySemantics)])
    }
}
