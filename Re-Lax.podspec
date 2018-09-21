Pod::Spec.new do |spec|
  spec.name = 'Re-Lax'
  spec.version = '1.0.1'
  spec.summary = 'Recreating Parallax on tvOS'
  spec.homepage = 'https://github.com/asynchrony/Re-Lax'
  spec.license = { :type => 'MIT', :file => 'LICENSE' }
  spec.author = {
    'Mark Sands' => 'mark.sands@asynchrony.com',
    'James Rantanen' => 'james.rantanen@asynchrony.com',
    'Asynchrony' => nil
  }
  spec.social_media_url = 'http://twitter.com/asynchrony'
  spec.source = { :git => 'https://github.com/asynchrony/Re-Lax.git', :tag => "v#{spec.version}" }
  spec.source_files = 'ReLax/ReLax/**/*.swift'
  spec.resources = ['ReLax/ReLax/blue-radiosity', 'ReLax/ReLax/bomTableStart', 'ReLax/ReLax/tmfkLayerData', 'ReLax/ReLax/tmfkPrefixData']
  
  spec.module_name = 'ReLax'
  spec.requires_arc = true
  spec.platform = ['tvos']
  spec.tvos.deployment_target = '9.0'
  spec.swift_version    = '4.1'
end
