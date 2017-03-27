import Foundation

struct ReLaxResource {
	private final class BundleClass { }
	
	static let bundle = Bundle(for: BundleClass.self)
	static let radiosityURL = bundle.url(forResource: "blue-radiosity", withExtension: nil)!
	static let tmfkPrefixData = bundle.url(forResource: "tmfkPrefixData", withExtension: nil)!
	static let tmfkLayerData = bundle.url(forResource: "tmfkLayerData", withExtension: nil)!
	static let bomTableStart = bundle.url(forResource: "bomTableStart", withExtension: nil)!
}
