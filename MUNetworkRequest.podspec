Pod::Spec.new do |s|
  s.name         = "MUNetworkRequest"
  s.version      = "0.9.1"
  s.license      = "MIT"
  s.summary      = "Network request based on AFNetworking."
  s.homepage     = "https://github.com/muer2000/MUNetworkRequest"
  s.author       = { "muer" => "muer2000@gmail.com" }
  s.platform     = :ios, "7.0"
  s.ios.deployment_target = "7.0"
  s.source       = { :git => "https://github.com/muer2000/MUNetworkRequest.git", :tag => s.version }
  s.source_files = "MUNetworkRequest/**/*"
  s.requires_arc = true
  s.dependency 'AFNetworking', '~> 3.1.0'
end
