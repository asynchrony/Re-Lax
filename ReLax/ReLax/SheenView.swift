import UIKit

class SheenView: UIImageView {
    private static let cache = NSCache<AnyObject, UIImage>()
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        image = SheenView.sheenImage()
    }
    
    static func key(forSize size: CGSize) -> AnyObject {
        return "\(size.width)x\(size.height)" as AnyObject
    }
    
    static func sheenViewSize(forSize size: CGSize) -> CGSize {
        let maxDimension = max(size.width, size.height)
        let sheenDimension = maxDimension * 1.1666666666
        return CGSize(width: sheenDimension, height: sheenDimension)
    }
    
    static func sheenImage() -> UIImage {
        let size = CGSize(width: 200, height: 200)
        let locations: [CGFloat] = [0.0, 0.5, 1.0]
        if let image = SheenView.cache.object(forKey: SheenView.key(forSize: size)) {
            return image
        } else {
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            guard let context = UIGraphicsGetCurrentContext() else { fatalError("can't create graphics context") }
            let colors = [0.2, 0.13, 0].map { UIColor(white: 1.0, alpha: $0).cgColor }
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceGray(), colors: colors as CFArray, locations: locations) else { fatalError("can't create gradient") }
            
            let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
            let radius = size.width / 2.0
            let centerRadius = size.width * 0.1
            context.drawRadialGradient(gradient, startCenter: center, startRadius: centerRadius, endCenter: center, endRadius: radius, options: [.drawsBeforeStartLocation])
            
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                SheenView.cache.setObject(image, forKey: SheenView.key(forSize: size))
            }
            
            UIGraphicsEndImageContext()
            
            return SheenView.cache.object(forKey: SheenView.key(forSize: size)) ?? UIImage()
        }
    }
}
