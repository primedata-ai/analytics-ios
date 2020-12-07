Pod::Spec.new do |s|
  s.name             = "Analytics"
  s.module_name      = "PrimeData"
  s.version          = "4.1.1"
  s.summary          = "The hassle-free way to add analytics to your iOS app."

  s.description      = <<-DESC
                       Analytics for iOS provides a single API that lets you
                       integrate with over 100s of tools.
                       DESC

  s.homepage         = "http://segment.com/"
  s.license          =  { :type => 'MIT' }
  s.author           = { "PrimeData" => "friends@segment.com" }
  s.source           = { :git => "https://github.com/segmentio/analytics-ios.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/segment'

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '9.0'

  s.ios.frameworks = 'CoreTelephony'
  s.frameworks = 'Security', 'StoreKit', 'SystemConfiguration', 'UIKit'

  s.source_files = [
    'PrimeData/Classes/**/*.{h,m}',
    'PrimeData/Internal/**/*.{h,m}'
  ]
end
