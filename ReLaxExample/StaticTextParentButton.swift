import UIKit
import ReLax

class StaticTextParentButton: UIButton {
	private let systemLabel = UILabel()
	private let exampleLabel = UILabel()
	
	let standardLCRView: UIImageView
	let exampleView: ParallaxView<DefaultContainer>
	
	init(standardLCR: UIImage, exampleView: ParallaxView<DefaultContainer>) {
		standardLCRView = UIImageView(image: standardLCR)
		self.exampleView = exampleView
		
		super.init(frame: CGRect.zero)
		
		standardLCRView.adjustsImageWhenAncestorFocused = true
		addSubview(standardLCRView)
		systemLabel.text = "Parallax Preview Image"
		systemLabel.textColor = .white
		addSubview(systemLabel)
		
		addSubview(exampleView)
		exampleLabel.text = "Static Text"
		exampleLabel.textColor = .white
		addSubview(exampleLabel)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let buttonSize = CGSize(width: 400, height: 600)
		let buttonAreaWidth = bounds.width / 2.0
		
		let (left, right) = bounds.divided(atDistance: buttonAreaWidth, from: .minXEdge)
		
		let sections = [left, right]
		let parallaxViews = [standardLCRView, exampleView]
		let labels = [systemLabel, exampleLabel]
		
		zip(parallaxViews, sections).forEach { $0.0.frame = buttonSize.centered(in: $0.1).offsetBy(dx: 0, dy: 75) }
		zip(labels, sections).forEach {
			let size = $0.0.sizeThatFits($0.1.size)
			$0.0.frame = size.centeredHorizontally(in: $0.1, top: 192)
		}
	}
	
	override public var isHighlighted: Bool {
		didSet {
			if isFocused {
				let focus: ParallaxFocusState = isHighlighted ? .focusedDepressed : .focused
				exampleView.setFocusState(focus, animationType: .animated)
			}
		}
	}
	
	override public func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
		super.didUpdateFocus(in: context, with: coordinator)
		exampleView.didUpdateFocus(in: context, with: coordinator)
	}
}
