import UIKit
import ReLax

class StaticTextViewController: UIViewController {
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		tabBarItem = UITabBarItem(title: "Static Text", image: nil, tag: 0)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func loadView() {
		guard let image = UIImage(contentsOfFile: Bundle.main.path(forResource: "monstersinc", ofType: "lcr")!) else { fatalError("monstersinc LCR missing") }
		
		let example = StaticTextExampleView(layerContainer: DefaultContainer(views: [UIImageView(image: image)]))
		let parallaxParent = StaticTextParentButton(standardLCR: image, exampleView: example)
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

class StaticTextExampleView: ParallaxView<DefaultContainer> {
	private let label = UILabel()
	
	override init(layerContainer: DefaultContainer, effectMultiplier: CGFloat = 1.0, sheenContainer: UIView? = nil) {
		super.init(layerContainer: layerContainer, effectMultiplier: effectMultiplier, sheenContainer: sheenContainer)
		label.text = "Release Date: 11/2/2001\nRunning Time: 1h 32m"
		label.numberOfLines = 0
		label.font = UIFont.boldSystemFont(ofSize: 30)
		label.textAlignment = .center
		label.textColor = .white
		label.shadowColor = UIColor(white: 0.0, alpha: 0.5)
		
		addSubview(label)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		label.frame = bounds.divided(atDistance: 150, from: .maxYEdge).slice
	}
}
