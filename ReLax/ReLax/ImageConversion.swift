import ImageIO
import MobileCoreServices
import UIKit

func JPEGData(from image: CGImage) -> Data {
    let imageData = NSMutableData()
    
    let options: [String : Any] = [
        kCGImageMetadataShouldExcludeXMP as String : true,
        kCGImageMetadataShouldExcludeGPS as String : true
    ]
    let imageDestination: CGImageDestination = CGImageDestinationCreateWithData(imageData, kUTTypeJPEG, 1, options as CFDictionary)!
    
    let properties: [String : Any] = [
        kCGImageDestinationLossyCompressionQuality as String : 1.0,
        kCGImageDestinationBackgroundColor as String : UIColor.black.cgColor
    ]
    
    CGImageDestinationAddImage(imageDestination, image, properties as CFDictionary)
    CGImageDestinationFinalize(imageDestination)
    
    return imageData as Data
}
