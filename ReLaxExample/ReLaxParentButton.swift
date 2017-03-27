import UIKit
import ReLax

class ReLaxParentButton: UIButton {
	private let systemLabel = UILabel()
	private let generatedLabel = UILabel()
	private let programatticLabel = UILabel()
	
	let standardLCRView: UIImageView
	let deviceGeneratedLCRView: UIImageView
	let realTimeImagesView: ParallaxView<DefaultContainer>
	
	init(standardLCR: UIImage, deviceGeneratedLCR: UIImage, realTimeImages: [UIImage]) {
		standardLCRView = UIImageView(image: standardLCR)
		deviceGeneratedLCRView = UIImageView(image: standardLCR)
        realTimeImagesView = ParallaxView(images: realTimeImages)
		
		super.init(frame: CGRect.zero)
		
		standardLCRView.adjustsImageWhenAncestorFocused = true
		addSubview(standardLCRView)
		systemLabel.text = "Parallax Preview Image"
		addSubview(systemLabel)
		
		deviceGeneratedLCRView.adjustsImageWhenAncestorFocused = true
		addSubview(deviceGeneratedLCRView)
		generatedLabel.text = "Generated Parallax Image"
		addSubview(generatedLabel)
		
		addSubview(realTimeImagesView)
		programatticLabel.text = "Programmatic Effect"
		addSubview(programatticLabel)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		let buttonSize = CGSize(width: 400, height: 600)
		let oneThirdWidth = bounds.width * 0.33
		
		let (left, remainder) = bounds.divided(atDistance: oneThirdWidth, from: .minXEdge)
		let (middle, right) = remainder.divided(atDistance: oneThirdWidth, from: .minXEdge)
		
		standardLCRView.frame = buttonSize.centered(in: left)
		deviceGeneratedLCRView.frame = buttonSize.centered(in: middle)
		realTimeImagesView.frame = buttonSize.centered(in: right)
		
		let thirds = [left, middle, right]
		let parallaxViews = [standardLCRView, deviceGeneratedLCRView, realTimeImagesView]
		let labels = [systemLabel, generatedLabel, programatticLabel]
		
		zip(parallaxViews, thirds).forEach { $0.frame = buttonSize.centered(in: $1).offsetBy(dx: 0, dy: 75) }
		zip(labels, thirds).forEach {
			let size = $0.sizeThatFits($1.size)
			$0.frame = size.centeredHorizontally(in: $1, top: 192)
		}
	}
	
	override public var isHighlighted: Bool {
		didSet {
			if isFocused {
				let focus: ParallaxFocusState = isHighlighted ? .focusedDepressed : .focused
				realTimeImagesView.setFocusState(focus, animationType: .animated)
			}
		}
	}
	
	override public func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
		super.didUpdateFocus(in: context, with: coordinator)
		realTimeImagesView.didUpdateFocus(in: context, with: coordinator)
	}
}
