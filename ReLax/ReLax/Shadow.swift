import UIKit

public struct Shadow {
	public var path: CGPath?
	public var opacity: CGFloat
	public var radius: CGFloat
	public var offset: CGSize
	public var color: CGColor
	
	public init(path: CGPath? = nil, opacity: CGFloat, radius: CGFloat, offset: CGSize, color: CGColor) {
		self.path = path
		self.opacity = opacity
		self.radius = radius
		self.offset = offset
		self.color = color
	}
	
	public func with(path: CGPath?) -> Shadow {
		var shadow = self
		shadow.path = path
		return shadow
	}
	
	public func with(opacity: CGFloat) -> Shadow {
		var shadow = self
		shadow.opacity = opacity
		return shadow
	}
	
	public func with(radius: CGFloat) -> Shadow {
		var shadow = self
		shadow.radius = radius
		return shadow
	}
	
	public func with(offset: CGSize) -> Shadow {
		var shadow = self
		shadow.offset = offset
		return shadow
	}
	
	public func with(color: CGColor) -> Shadow {
		var shadow = self
		shadow.color = color
		return shadow
	}
}

extension CALayer {
	public func apply(shadow: Shadow?) {
		if let shadow = shadow {
			shadowPath = shadow.path
			shadowRadius = shadow.radius
			shadowOpacity = Float(shadow.opacity)
			shadowOffset = shadow.offset
			shadowColor = shadow.color
		} else {
			shadowOpacity = 0
		}
	}
}
