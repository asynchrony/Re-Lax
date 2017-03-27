import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		let tabs = UITabBarController()
		tabs.setViewControllers([JaggedEdgeViewController(), StaticTextViewController(), ReLaxViewController()], animated: false)
		window = UIWindow()
		window?.makeKeyAndVisible()
		window?.rootViewController = tabs
		return true
	}
}
