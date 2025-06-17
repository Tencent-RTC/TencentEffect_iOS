#
# Be sure to run `pod lib lint TEBeautyKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TEBeautyKit'
  s.version          = '1.0.0'
  s.summary          = 'A short description of TEBeautyKit.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/originleeli@tencent.com/TEBeautyKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'originleeli@tencent.com' => 'originleeli@tencent.com' }
  s.source           = { :git => 'https://github.com/originleeli@tencent.com/TEBeautyKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.static_framework = true
  s.source_files = ['TEBeautyKit/Classes/**/*.{m,h}','TEBeautyKit/Classes/*.{m,h}']
  
   s.resource_bundles = {
     'TEBeautyKitResources' => [
     'TEBeautyKit/Assets/BeautyRes/**/*.png',
     'TEBeautyKit/Assets/BeautyRes/**/**/*.png',
     'TEBeautyKit/Assets/en.lproj/Localizable.strings',
     'TEBeautyKit/Assets/zh-Hans.lproj/Localizable.strings',
     'TEBeautyKit/Assets/json/beauty_panel/**/*'
     ]
   }
   

   s.public_header_files = ['TEBeautyKit/Classes/**/*.h','TEBeautyKit/Classes/*.h']
   
   s.dependency 'TencentEffect_S1-07'
   s.dependency 'Masonry'
   s.dependency 'SSZipArchive'
   s.dependency 'AFNetworking'
end
