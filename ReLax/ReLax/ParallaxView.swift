import UIKit

public enum ParallaxFocusState: Equatable {
	case unfocused
	case focused
	case focusedDepressed
}

public func ==(rhs: ParallaxFocusState, lhs: ParallaxFocusState) -> Bool {
	switch (rhs, lhs) {
	case (.focused, .focused): fallthrough
	case (.unfocused, .unfocused): fallthrough
	case (.focusedDepressed, .focusedDepressed):
		return true
	default:
		return false
	}
}

public protocol ParallaxContainer {
	func focusChanged(_ focus: ParallaxFocusState)
	func parallaxShadow(forFocus: ParallaxFocusState, defaultShadow: Shadow) -> Shadow?
}

public enum FocusAnimationType {
	case animated
	case coordinated(UIFocusAnimationCoordinator)
	case none
	
	public func animate(_ action: @escaping () -> ()) {
		switch self {
		case .animated:
			UIView.animate(withDuration: 0.15,
			               delay: 0,
			               options: [.beginFromCurrentState, .allowUserInteraction],
			               animations: action,
			               completion: nil)
		case .coordinated(let coordinator):
			coordinator.addCoordinatedAnimations(action, completion: nil)
		case .none:
			action()
		}
	}
}

open class ParallaxView<Container: UIView>: AnimatedShadowView where Container: ParallaxContainer {
	fileprivate let sheenView = SheenView()
	fileprivate let container: Container
	fileprivate let sheenContainer: UIView
	fileprivate let shadowPathView = AnimatedShadowView()
	fileprivate let effectMultiplier: CGFloat
	fileprivate var parallaxLayers: [UIView] { return container.subviews.filter { return $0 != sheenContainer } }
	open var canFocus: Bool = true
	open private(set) var focusState = ParallaxFocusState.unfocused
	
	open var cornerRadius: CGFloat {
		get { return container.layer.cornerRadius }
		set { container.layer.cornerRadius = newValue }
	}
	
	open override var canBecomeFocused : Bool {
		return canFocus
	}
	
	public convenience init(images: [UIImage]) {
		let imageViews = images.map(UIImageView.init)
		imageViews.forEach { $0.contentMode = .scaleAspectFill }
		guard let container = DefaultContainer(views: imageViews) as? Container else { fatalError("Swift fail") }
		self.init(layerContainer: container)
	}
	
	// All direct subviews of layerContainer will be used to create the parallax effect
	// layerContainer is responsible for layout of its subviews
	// layerContainer will be clipped to bounds unless separate sheen container is provided
	public init(layerContainer: Container, effectMultiplier: CGFloat = 1.0, sheenContainer: UIView? = nil) {
		container = layerContainer
		self.sheenContainer = sheenContainer ?? layerContainer
		self.effectMultiplier = effectMultiplier
		self.sheenContainer.layer.masksToBounds = true
		super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
		parallaxLayers.first?.layer.allowsEdgeAntialiasing = true
		container.layer.allowsEdgeAntialiasing = true
		addSubview(shadowPathView)
		addSubview(container)
		self.sheenContainer.addSubview(sheenView)
		onUnFocus()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		shadowPathView.frame = bounds
		container.frame = bounds
		
		let sheenSize = SheenView.sheenViewSize(forSize: bounds.size)
		let sheenRect = CGRect(origin: CGPoint(x: bounds.midX - (sheenSize.width / 2.0), y: -(sheenSize.height / 2.0) - 20), size: sheenSize)
		sheenView.frame = sheenContainer.convert(sheenRect, from: container)
		
		setFocusState(focusState, animationType: .none, forceUpdate: true)
	}
	
	open override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
		if let focusingView = context.nextFocusedView , self.isDescendant(of: focusingView)  {
			setFocusState(.focused, animationType: .coordinated(coordinator))
		} else if let unfocusingView = context.previouslyFocusedView , self.isDescendant(of: unfocusingView) {
			setFocusState(.unfocused, animationType: .coordinated(coordinator))
		}
	}
	
	open func setFocusState(_ focus: ParallaxFocusState, animationType: FocusAnimationType, forceUpdate: Bool = false) {
		guard forceUpdate || focusState != focus else { return }
		
		focusState = focus
		
		let focusAction: () -> ()
		switch focus {
		case .focused:
			focusAction = onFocus
		case .focusedDepressed: fallthrough
		case .unfocused:
			focusAction = onUnFocus
		}
		
		animationType.animate {
			focusAction()
			self.container.focusChanged(focus)
		}
	}
	
	public func clearAnimations() {
		let views: [UIView] = [shadowPathView, container] + container.subviews
		views.forEach {
			$0.layer.removeAllAnimations()
		}
	}
	
	lazy var onFocus: () -> () = {  [weak self] in
		guard let view = self else { return }
		let effectMultiplier = view.effectMultiplier
		
		let mainEffects = [TvMotionEffect
			.forContainerSize(view.container.bounds.size)
			.effectMultiplier(effectMultiplier)
			.motionEffect]
		
		view.container.motionEffects = mainEffects
		view.shadowPathView.motionEffects = mainEffects
		
		var layerIndex = 0
		view.parallaxLayers.forEach {
			$0.motionEffects = [TvMotionEffect
				.forLayer(layerIndex, numberOfLayers: view.parallaxLayers.count, containerSize: view.container.bounds.size)
				.effectMultiplier(effectMultiplier)
				.motionEffect]
			layerIndex += 1
		}
		view.sheenView.alpha = 1.0
		view.sheenView.motionEffects = [TvMotionEffect
			.forSheen(view.container.bounds.size)
			.effectMultiplier(effectMultiplier)
			.motionEffect]
		
		view.maybeApplyShadow(true)
	}
	
	lazy var onUnFocus: () -> () = { [weak self] in
		guard let view = self else { return }
		view.sheenView.alpha = 0.0
		view.container.motionEffects = []
		view.shadowPathView.motionEffects = []
		view.parallaxLayers.forEach { $0.motionEffects = [] }
		
		view.maybeApplyShadow(false)
	}
	
	public func maybeApplyShadow(_ focused: Bool) {
		let defaultShadow = Shadow(
			path: nil,
			opacity: focused ? 0.525 : 0.25,
			radius: focused ? 40.0 * effectMultiplier : 5.0,
			offset: CGSize(width: 0, height: focused ? 50 * effectMultiplier : 4),
			color: UIColor.black.cgColor
		)
		
		if let shadow = container.parallaxShadow(forFocus: focusState, defaultShadow: defaultShadow) {
			CATransaction.begin()
			CATransaction.setAnimationDuration(UIView.inheritedAnimationDuration)
			
			let hasShadowPath = shadow.path != nil
			
			shadowPathView.isHidden = !hasShadowPath
			shadowPathView.layer.apply(shadow: hasShadowPath ? shadow : nil)
			layer.apply(shadow: hasShadowPath ? nil : shadow)
			
			CATransaction.commit()
		} else {
			layer.apply(shadow: nil)
			shadowPathView.isHidden = true
		}
	}
}

open class AnimatedShadowView: UIView {
	override open func action(for layer: CALayer, forKey event: String) -> CAAction? {
		let action = super.action(for: layer, forKey: event)
		
		let keys = ["shadowRadius", "shadowOpacity", "shadowOffset"]
		if keys.contains(event) {
			let animation = CABasicAnimation(keyPath: event)
			animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
			return animation
		}
		
		return action
	}
}
