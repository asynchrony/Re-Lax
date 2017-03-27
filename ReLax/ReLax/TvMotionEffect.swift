import UIKit

public struct TvMotionEffect {
    public static let defaultTranslation: CGFloat = 10
    public static let defaultPerspective: CGFloat = 0.000085

	let motionEffect = UIMotionEffectGroup()
	fileprivate let scale: CGFloat
	fileprivate let perspective: CGFloat
	fileprivate let xTranslation: CGFloat
	fileprivate let yTranslation: CGFloat
	fileprivate let effectMultiplier: CGFloat
	
    public init(scale: CGFloat, perspective: CGFloat, translation: CGFloat) {
        self.init(scale: scale, perspective: perspective, xTranslation: translation, yTranslation: translation)
    }
    
	public init(scale: CGFloat, perspective: CGFloat, xTranslation: CGFloat, yTranslation: CGFloat, effectMultiplier: CGFloat = 1.0) {
		self.scale = (scale - 1.0) * effectMultiplier + 1.0
		self.perspective = perspective * effectMultiplier
		self.xTranslation = xTranslation * effectMultiplier
		self.yTranslation = yTranslation * effectMultiplier
		self.effectMultiplier = effectMultiplier
        let xTransform = UIInterpolatingMotionEffect(keyPath: "layer.transform", type: .tiltAlongVerticalAxis)
        xTransform.minimumRelativeValue = NSValue(caTransform3D: TvMotionEffect.transform(scale: self.scale, perspectiveX: self.perspective, perspectiveY: 0.0, translationX: 0, translationY: -self.yTranslation))
        xTransform.maximumRelativeValue = NSValue(caTransform3D: TvMotionEffect.transform(scale: self.scale, perspectiveX: -self.perspective, perspectiveY: 0.0, translationX: 0, translationY: self.yTranslation))
        
        let yTransform = UIInterpolatingMotionEffect(keyPath: "layer.transform", type: .tiltAlongHorizontalAxis)
        yTransform.minimumRelativeValue = NSValue(caTransform3D: TvMotionEffect.transform(scale: 1, perspectiveX: 0.0, perspectiveY: self.perspective, translationX: -self.xTranslation, translationY: 0))
        yTransform.maximumRelativeValue = NSValue(caTransform3D: TvMotionEffect.transform(scale: 1, perspectiveX: 0.0, perspectiveY: -self.perspective, translationX: self.xTranslation, translationY: 0))
        
        motionEffect.motionEffects = [xTransform, yTransform]
    }
	
	public func effectMultiplier(_ effectMultiplier: CGFloat) -> TvMotionEffect {
		return TvMotionEffect(scale: scale,
		                      perspective: perspective,
		                      xTranslation: xTranslation,
		                      yTranslation: yTranslation,
		                      effectMultiplier: effectMultiplier)
	}
	
    public static func forContainerSize(_ size: CGSize) -> TvMotionEffect {
        let translation = TvMotionEffect.defaultTranslation
        let perspective = TvMotionEffect.defaultPerspective
        let scale: CGFloat = 1.0 + (70.0 / max(size.width, size.height))
        return TvMotionEffect(scale: scale, perspective: perspective, translation: translation)
    }
    
    public static func forLayer(_ layerIndex: Int, numberOfLayers: Int, containerSize: CGSize) -> TvMotionEffect {
        let layerEffectMultiplier: CGFloat = CGFloat(layerIndex) / CGFloat(max(numberOfLayers - 1, 1))
        let maxDimension = max(containerSize.width, containerSize.height)
        let maxScale: CGFloat = 0.072
        let scaleMultiplier: CGFloat = min(maxDimension / 300.0, 1.0)
        
        // don't allow a point to translate further backwards than it has translated due to the scale
        // this happens only in small views (~150 points or smaller)
        let maxTranslation = (maxScale * scaleMultiplier) * (maxDimension / 2.0)
        
        let translation: CGFloat = -min(maxTranslation, 3.2) * layerEffectMultiplier
        let scale: CGFloat = 1.0 + (maxScale * scaleMultiplier * layerEffectMultiplier)
        return TvMotionEffect(scale: scale, perspective: 0.0, translation: translation)
    }
    
    public static func forSheen(_ containerSize: CGSize) -> TvMotionEffect {
        let translationModifier: CGFloat = 20
        return TvMotionEffect(scale: 1.0, perspective: 0.0, xTranslation: containerSize.width - translationModifier, yTranslation: containerSize.height - translationModifier + 40)
    }
    
    static func transform(scale: CGFloat, perspectiveX: CGFloat, perspectiveY: CGFloat, translationX: CGFloat, translationY: CGFloat) -> CATransform3D {
        return CATransform3D(
            m11: scale,             m12: 0.0,               m13: 0.0,               m14: perspectiveY,
            m21: 0.0,               m22: scale,             m23: 0.0,               m24: perspectiveX,
            m31: 0.0,               m32: 0.0,               m33: 1.0,               m34: 0.0,
            m41: translationX,      m42: translationY,      m43: 0.0,               m44: 1.0)
    }
}
