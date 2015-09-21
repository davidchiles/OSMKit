Pod::Spec.new do |spec|
  spec.name         = 'OSMKit'
  spec.version      = '0.1'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/davidchiles/OSMKit'
  spec.authors      = { 'David Chiles' => 'dwalterc@gmail.com' }
  spec.summary      = 'OpenStreetMap library for iOS and OS X'
  spec.source       = { :git => 'https://github.com/davidchiles/OSMKit', :tag => 'v0.2' }
  spec.requires_arc = true

  spec.platform = :ios, "7.0"
  # spec.dependency "SpatialDBKit"
  spec.dependency 'AFNetworking', '~> 2.6'
  spec.dependency 'TBXML', '~> 1.5'
  spec.dependency 'gtm-oauth', '~> 0.0'
  spec.dependency 'KissXML', '~> 5.0'

  spec.xcconfig = { 'HEADER_SEARCH_PATHS' => '/usr/include/libxml2' }


  spec.source_files = 'OSMKit/*.{h,m}','OSMKit/**/*.{h,m}','OSMKit/**/**/*.{h,m}'
  spec.public_header_files = 'OSMKit/*.{h}', "OSMKit/**/*.{h}", "OSMKit/**/**/*.{h}"

end
