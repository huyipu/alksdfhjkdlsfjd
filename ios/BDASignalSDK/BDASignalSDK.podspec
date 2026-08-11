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

  # 注意：SDK 自带的 PrivacyInfo.xcprivacy 不再单独进包，
  # 其声明（DiskSpace E174.1 / FileTimestamp DDA9.1 / UserDefaults CA92.1）
  # 已按 Apple 静态库要求合并进 App 级 ios/Runner/PrivacyInfo.xcprivacy，
  # 否则两份同名清单会导致 "Multiple commands produce" 构建冲突。

  s.frameworks          = 'UIKit', 'Foundation'
  s.libraries           = 'z', 'c++'

  s.dependency 'Protobuf'
end
