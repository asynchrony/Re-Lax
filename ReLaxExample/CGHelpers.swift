// https://gist.github.com/JARinteractive/96cbba8f35dcd10bbb77

import UIKit

extension CGSize {
	public func centered(in rect: CGRect) -> CGRect {
		let centeredPoint = CGPoint(x: rect.minX + abs(rect.width - width) / 2, y: rect.minY + abs(rect.height - height) / 2)
		let size = CGSize(width: min(self.width, rect.width), height: min(self.height, rect.height))
		let point = CGPoint(x: max(centeredPoint.x, rect.minX), y: max(centeredPoint.y, rect.minY))
		return CGRect(origin: point, size: size)
	}
	
	public func centeredHorizontally(in rect: CGRect, top: CGFloat) -> CGRect {
		var rect = centered(in: rect)
		rect.origin.y = top
		return rect
	}
	
	public func centeredVertically(in rect: CGRect, left: CGFloat) -> CGRect {
		var rect = centered(in: rect)
		rect.origin.x = left
		return rect
	}
}

public struct AlignmentStrategy {
	let xAlignment: (CGFloat) -> CGFloat
	let yAlignment: (CGFloat) -> CGFloat
	let widthAlignment: (CGFloat) -> CGFloat
	let heightAlignment: (CGFloat) -> CGFloat
	
	public static let scale = UIScreen.main.scale
	
	init(alignment: @escaping (CGFloat) -> CGFloat) {
		xAlignment = alignment
		yAlignment = alignment
		widthAlignment = alignment
		heightAlignment = alignment
	}
	
	init(originAlignment: @escaping (CGFloat) -> CGFloat, sizeAlignment: @escaping (CGFloat) -> CGFloat) {
		xAlignment = originAlignment
		yAlignment = originAlignment
		widthAlignment = sizeAlignment
		heightAlignment = sizeAlignment
	}
	
	init(xAlignment: @escaping (CGFloat) -> CGFloat, yAlignment: @escaping (CGFloat) -> CGFloat, widthAlignment: @escaping (CGFloat) -> CGFloat, heightAlignment: @escaping (CGFloat) -> CGFloat) {
		self.xAlignment = xAlignment
		self.yAlignment = yAlignment
		self.widthAlignment = widthAlignment
		self.heightAlignment = heightAlignment
	}
	
	func align(rect: CGRect) -> CGRect {
		return CGRect(x: xAlignment(rect.origin.x), y: yAlignment(rect.origin.y), width: widthAlignment(rect.width), height: heightAlignment(rect.height))
	}
	
	public static var roundToPixel: AlignmentStrategy {
		return AlignmentStrategy {
			return round($0 * AlignmentStrategy.scale) / AlignmentStrategy.scale
		}
	}
	
	public static var label: AlignmentStrategy {
		return AlignmentStrategy {
			return ceil($0 * AlignmentStrategy.scale) / AlignmentStrategy.scale
		}
	}
}

extension CGRect {
	public func align(strategy: AlignmentStrategy = .roundToPixel) -> CGRect {
		return strategy.align(rect: self)
	}
	
	public var center:CGPoint {
		return CGPoint(x: midX, y: midY)
	}
	
	public static var nonZero: CGRect { return CGRect(x: 0, y: 0, width: 100, height: 100) }
	
	public init(x: CGFloat, y: CGFloat, size: CGSize) {
		self.init(x: x, y: y, width: size.width, height: size.height)
	}
	
	public init(origin: CGPoint, width: CGFloat, height: CGFloat) {
		self.init(x: origin.x, y: origin.y, width: width, height: height)
	}
}

public func -(point1: CGPoint, point2: CGPoint) -> CGSize {
	return CGSize(width: point1.x - point2.x, height: point1.y - point2.y)
}

public func +(point: CGPoint, size: CGSize) -> CGPoint {
	return CGPoint(x: point.x - size.width, y: point.y - size.height)
}
