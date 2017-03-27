import UIKit
import ReLax

class ReLaxViewController: UIViewController {
	private var parallaxParent: ReLaxParentButton?
	private var button: UIButton?
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		tabBarItem = UITabBarItem(title: "Re:Lax", image: nil, tag: 0)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func loadView() {
		guard let standard = UIImage(contentsOfFile: Bundle.main.path(forResource: "TheIncredibles", ofType: "lcr")!) else { fatalError("standard LCR missing") }
		guard let generated = generateLCR() else { fatalError("generated LCR missing") }
		let parallaxParent = ReLaxParentButton(standardLCR: standard, deviceGeneratedLCR: generated, realTimeImages: images)
		view = parallaxParent
	}
	
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		guard let view = view, let parallaxParent = parallaxParent, let button = button else { return }
		
		let remainder: CGRect
		(remainder, parallaxParent.frame) = view.bounds.divided(atDistance: 250, from: .maxYEdge)
		
		button.frame = button.sizeThatFits(remainder.size).centered(in: remainder)
	}
	
	private var images: [UIImage] {
        return (1...5)
			.map { "theincredibles-\($0)" }
			.map { UIImage(named: $0)! }
	}
	
	private func generateLCR() -> UIImage? {
        let parallaxImage = ParallaxImage(images: Array(images.reversed()))
        return parallaxImage.image()
	}
}
