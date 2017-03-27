import Foundation
import Accelerate
import Compression
import CoreGraphics
import ImageIO
import MobileCoreServices
import UIKit

struct LCRFlattenedRendition {
    private let imageName = "Image-Flattened"
    private let image: CGImage
    private let imageWidth: Int
    private let imageHeight: Int
    private let csiHeader: CoreStructuredImage
    
    init(images: [LCRLayer], size: CGSize) {
        imageWidth = Int(size.width)
        imageHeight = Int(size.width)
        csiHeader = CoreStructuredImage.flattened(imageName: imageName)
        
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: Int(size.width) * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        images.forEach {
            let rect = LCRFlattenedRendition.contextRect(for: $0.imageRect, contextSize: size)
            context.draw($0.image, in: rect)
        }
        
        image = context.makeImage()!
    }
    
    private static func contextRect(for imageRect: CGRect, contextSize: CGSize) -> CGRect {
        let ratio: CGFloat = min(contextSize.width / imageRect.width, imageRect.height / contextSize.height)
        return CGRect(x: 0, y: 0, width: imageRect.width * ratio, height: imageRect.height * ratio)
    }
    
    func data() -> Data {
        let infoListData = structuredImage()
        let image = imageData()
        return concatData([csiHeader.data(structuredInfoDataLength: infoListData.count, payloadDataLength: image.count), infoListData, image])
    }
    
    private func structuredImage() -> Data {
        return concatData([
            StructuredInfo.composition.data(),
            StructuredInfo.exifOrientation.data()
        ])
    }
    
    private func imageData() -> Data {
        let jpeg = JPEGData(from: image)
        let rawd = "DWAR".data(using: String.Encoding.ascii)!
        
        return concatData([rawd, int32Data(0), int32Data(jpeg.count), jpeg])
    }
}
