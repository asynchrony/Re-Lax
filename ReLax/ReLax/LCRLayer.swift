import Accelerate
import Compression
import UIKit

struct LCRLayer {
    let imageName: String
    let image: CGImage
    let imageWidth: Int
    let imageHeight: Int
    let imageRect: CGRect
    private let alpha: Data
    private let csiHeader: CoreStructuredImage

    init(layer: LCRLayerSource, name: String = "Image-" + uuidHexString()) {
        imageName = name
        imageWidth = layer.image.width
        imageHeight = layer.image.height
        imageRect = CGRect(origin: layer.origin, size: CGSize(width: imageWidth, height: imageHeight))
        csiHeader = CoreStructuredImage.layer(imageName: imageName, imageSize: CGSize(width: imageWidth, height: imageHeight))
        
        let context = CGContext(data: nil, width: imageWidth, height: imageHeight, bitsPerComponent: 8, bytesPerRow: imageWidth * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(layer.image, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
        image = context.makeImage()!
        
        let imageData = context.data
        var imageBuffer = vImage_Buffer(data: imageData, height: UInt(imageHeight), width: UInt(imageWidth), rowBytes: imageWidth * 4)
		var alphaChannel = vImage_Buffer(data: UnsafeMutableRawPointer(malloc(imageWidth * imageHeight)), height: UInt(imageHeight), width: UInt(imageWidth), rowBytes: imageWidth)
		
        let vImageError = vImageExtractChannel_ARGB8888(&imageBuffer, &alphaChannel, 3, UInt32(kvImageNoFlags))
		guard vImageError == 0 else { fatalError("Unable to populate Alpha Channel Buffer") }
		
        let alphaChannelBufferAsUInt8 = unsafeBitCast(alphaChannel.data, to: UnsafeMutablePointer<UInt8>.self)
		let encodedAlphaChannel = unsafeBitCast(malloc(imageWidth * imageHeight), to: UnsafeMutablePointer<UInt8>.self)
		let sizeOfEncodedAlphaChannel = compression_encode_buffer(encodedAlphaChannel, imageWidth * imageHeight, alphaChannelBufferAsUInt8, imageWidth * imageHeight, nil, COMPRESSION_LZFSE)
		guard sizeOfEncodedAlphaChannel > 0 else { fatalError("Alpha Channel Buffer is 0 length") }
        
		alpha = Data(bytes: encodedAlphaChannel, count: sizeOfEncodedAlphaChannel)
		free(alphaChannel.data)
        free(encodedAlphaChannel)
    }
    
    func data() -> Data {
        let infoListData = structuredImageData()
        let coreElemData = coreElementData()
        return concatData([csiHeader.data(structuredInfoDataLength: infoListData.count, payloadDataLength: coreElemData.count), infoListData, coreElementData()])
    }
    
    private func coreElementData() -> Data {
        let celm = "MLEC".data(using: .ascii)!
        let lzsfeCompressionId = 5
        let compressionType = int32Data(lzsfeCompressionId)
        let image = imageData()
        let imageByteCount = int32Data(image.count)
        
        return concatData([celm, zeroPadding(4), compressionType, imageByteCount, image])
    }
    
    private func structuredImageData() -> Data {
        return concatData([
            StructuredInfo.slices(width: imageWidth, height: imageHeight).data(),
            StructuredInfo.metrics(width: imageWidth, height: imageHeight).data(),
            StructuredInfo.composition.data(),
            StructuredInfo.exifOrientation.data(),
            StructuredInfo.bytesPerRow(width: imageWidth).data()
            ])
    }
    
    private func imageData() -> Data {
        let jpeg = JPEGData(from: image)
        return concatData([zeroPadding(8), int32Data(alpha.count), int32Data(imageWidth), int32Data(jpeg.count), alpha, jpeg])
    }
}
