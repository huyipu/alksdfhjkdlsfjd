Pod::Spec.new do |s|
  s.name                = 'BDASignalSDK'
  s.version             = '0.0.4'
  s.summary             = '巨量引擎转化SDK（本地静态库接入）'
  s.description         = '巨量引擎转化SDK iOS 端静态库，用于广告归因事件上报。'
  s.homepage            = 'https://www.oceanengine.com'
  s.license             = { :type => 'MIT' }
  s.author              = { 'OceanEngine' => 'dev@oceanengine.com' }
  s.platform            = :ios, '13.0'
  s.source              = { :path => '.' }

  s.source_files        = 'BDASignalSDK/*.h'
  s.public_header_files = 'BDASignalSDK/*.h'
  s.vendored_libraries  = 'libBDASignalSDK.a'

  # Apple 隐私合规清单（随包分发，见 docs/巨量归因方案_iOS端接入指引.md）
  s.resource            = 'PrivacyInfo.xcprivacy'

  s.frameworks          = 'UIKit', 'Foundation'
  s.libraries           = 'z', 'c++'

  s.dependency 'Protobuf'
end
