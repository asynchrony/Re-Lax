import UIKit

open class DefaultContainer: UIView, ParallaxContainer {
	fileprivate let views: [UIView]
	
	// all views will be sized to fill the container
	public init(views: [UIView]) {
		self.views = views
		super.init(frame: CGRect.zero)
		layer.allowsEdgeAntialiasing = true
		views.forEach(addSubview)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		
		views.forEach { $0.frame = self.bounds }
	}
	
	open func focusChanged(_ focus: ParallaxFocusState) { }
	open func parallaxShadow(forFocus focus: ParallaxFocusState, defaultShadow: Shadow) -> Shadow? { return defaultShadow }
}

open class ParallaxButton<Container: UIView>: UIButton where Container: ParallaxContainer {
	public let parallaxView: ParallaxView<Container>
	
	open override var isHighlighted: Bool {
		didSet {
			let focus: ParallaxFocusState = isHighlighted ? .focusedDepressed : .focused
			parallaxView.setFocusState(focus, animationType: .animated)
		}
	}
	
	public init(images: [UIImage]) {
		parallaxView = ParallaxView(images: images)
		parallaxView.canFocus = false
		super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
		addSubview(parallaxView)
	}
	
	// All direct subviews of layerContainer will be used to create the parallax effect
	// layerContainer is responsible for layout of its subviews
	// layerContainer will be clipped to bounds
	public init(layerContainer: Container, effectMultiplier: CGFloat = 1.0) {
		parallaxView = ParallaxView(layerContainer: layerContainer, effectMultiplier: effectMultiplier)
		parallaxView.canFocus = false
		super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
		addSubview(parallaxView)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		parallaxView.frame = bounds
	}
	
	open override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
		super.didUpdateFocus(in: context, with: coordinator)
		parallaxView.didUpdateFocus(in: context, with: coordinator)
	}
}
