import UIKit

enum CoreStructuredImage {
    case flattened(imageName: String)
    case layer(imageName: String, imageSize: CGSize)
    case layeredImage(imageName: String, imageSize: CGSize)

    private var pixelFormat: String {
        switch self {
        case .flattened(_):
            return "GEPJ"
        case .layer(_, _):
            return "BGRA"
        case .layeredImage(_, _):
            return "ATAD"
        }
    }
    
    private var colorSpaceID: Int {
        switch self {
        case .flattened(_), .layeredImage(_, _):
            return 15
        case .layer(_, _):
            return 1
        }
    }
    
    // Type of Rendition
    private var layout: Int {
        switch self {
        case .flattened(_), .layer(_, _):
            return 10
        case .layeredImage(_, _):
            return 0x03EA
        }
    }
    
    private var imageSize: CGSize {
        switch self {
        case .flattened(_):
            return .zero
        case .layer(_, let size):
            return size
        case .layeredImage(_, let size):
            return size
        }
    }
    
    private var imageName: String {
        switch self {
        case .flattened(let name):
            return name
        case .layer(let name, _):
            return name
        case .layeredImage(let name, _):
            return name
        }
    }
    
    func data(structuredInfoDataLength: Int, payloadDataLength: Int) -> Data {
        let infoListLength = int32Data(structuredInfoDataLength)
        let bitmapInfoData = bitmapInfo(payloadLength: payloadDataLength)
        return concatData([renditionHeader(), metaData(), infoListLength, bitmapInfoData])
    }
    
    private func renditionHeader() -> Data {
        let ctsi = "ISTC".data(using: .ascii)!
        let version = int32Data(1)
        let renditionFlags = int32Data(0) // unused
        let width = int32Data(Int(imageSize.width))
        let height = int32Data(Int(imageSize.height))
        let scale = int32Data(100) // 100 = 1x, 200 = 2x
        let pixelFormat = self.pixelFormat.data(using: .ascii)!
        let colorSpaceIDData = int32Data(self.colorSpaceID)
        return concatData([ctsi, version, renditionFlags, width, height, scale, pixelFormat, colorSpaceIDData])
    }
    
    private func metaData() -> Data {
        let modifiedDate = int32Data(0)
        let layout = int32Data(self.layout)
        let nameData = self.imageName.padded(count: 128)
        return concatData([modifiedDate, layout, nameData])
    }
    
    private func bitmapInfo(payloadLength: Int) -> Data {
        let bitmapCount = int32Data(1)
        let reserved = int32Data(0)
        let payloadSize = int32Data(payloadLength)
        return concatData([bitmapCount, reserved, payloadSize])
    }
}
