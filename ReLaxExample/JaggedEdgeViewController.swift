import UIKit
import ReLax

class JaggedEdgeViewController: UIViewController {
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		tabBarItem = UITabBarItem(title: "Jagged Edge", image: nil, tag: 0)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func loadView() {
		let example = ParallaxView<DefaultContainer>(layerContainer: DefaultContainer(views: [ExampleView()]))
		
		guard let standard = UIImage(contentsOfFile: Bundle.main.path(forResource: "walle", ofType: "lcr")!) else { fatalError("standard LCR missing") }
		let parallaxParent = JaggedEdgeParentButton(standardLCR: standard, exampleView: example)
		view = parallaxParent
		view.backgroundColor = .darkGray
	}
	
	private var images: [UIImage] {
		return (1...5)
			.map { "\($0)" }
			.map { UIImage(contentsOfFile: Bundle.main.path(forResource: $0, ofType: "png")!)! }
	}
	
	private func generateLCR() -> UIImage? {
		let parallaxImage = ParallaxImage(images: Array(images.reversed()))
		return parallaxImage.image()
	}
}

class ExampleView: UIView {
	let border = UIView()
	let imageView = UIImageView()
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		guard let image = UIImage(contentsOfFile: Bundle.main.path(forResource: "walle", ofType: "lcr")!) else { fatalError("walle LCR missing") }
		border.backgroundColor = .white
		
		imageView.backgroundColor = .black
		imageView.image = image
		imageView.adjustsImageWhenAncestorFocused = false
		
		addSubview(border)
		addSubview(imageView)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		border.frame = bounds.insetBy(dx: 1, dy: 1)
		imageView.frame = bounds.insetBy(dx: 4, dy: 4)
	}
}
