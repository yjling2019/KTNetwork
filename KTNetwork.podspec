#
# Be sure to run `pod lib lint KTNetwork.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KTNetwork'
  s.version          = '0.1.0'
  s.summary          = 'KOTU\'s network library.'
  s.homepage         = 'https://github.com/yjling2019/KTNetwork'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'KOTU' => 'yjling2019@gmail.com' }
  s.source           = { :git => 'https://github.com/yjling2019/KTNetwork.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files = 'KTNetwork/Classes/**/*'
  s.dependency 'AFNetworking', '~> 4.0'

end
