Pod::Spec.new do |spec|
  spec.name         = 'OSMKit'
  spec.version      = '0.1'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/davidchiles/OSMKit'
  spec.authors      = { 'David Chiles' => 'dwalterc@gmail.com' }
  spec.summary      = 'OpenStreetMap library for iOS and OS X'
  spec.source       = { :git => 'https://github.com/davidchiles/OSMKit', :tag => 'v0.1' }
  spec.requires_arc = true

  spec.platform = :ios, "7.0"
  spec.dependency "SpatialDBKit"
  spec.dependency "AFNetworking"
  spec.dependency "TBXML"
  spec.dependency "gtm-oauth"
  spec.dependency "KissXML"
  spec.dependency "Ono"

  spec.xcconfig = { 'HEADER_SEARCH_PATHS' => '/usr/include/libxml2' }


  spec.source_files = 'OSMKit/**/*.{h,m}','OSMKit/**/**/*.{h,m}'
  spec.public_header_files = "OSMKit/**/*.{h}", "OSMKit/**/**/*.{h}"

end