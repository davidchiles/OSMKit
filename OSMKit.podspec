Pod::Spec.new do |spec|
  spec.name         = 'OSMKit'
  spec.version      = '0.1'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/davidchiles/OSMKit'
  spec.authors      = { 'David Chiles' => 'dwalterc@gmail.com' }
  spec.summary      = 'OpenStreetMap library for iOS and OS X'
  spec.source       = { :git => 'https://github.com/davidchiles/OSMKit', :tag => 'v0.1' }
  spec.requires_arc = true

  s.platform = :ios, "5.0"
  s.dependency = "SpatialDBKit"

  spec.source_files = 'OSMKit.{h,m}'
  s.public_header_files = "OSMKit.{h}"

end