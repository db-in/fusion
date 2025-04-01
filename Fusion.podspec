Pod::Spec.new do |s|
  s.name = "Fusion"
  s.version = "1.1.84"
  s.summary = "Micro Feature"
  s.description = <<-DESC
				  Fusion is resposible for ...
				  DESC
  s.homepage = "https://fusion.com"
  s.documentation_url = "https://db-in.github.io/fusion/"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = 'Diney Bomfim'
  s.source = { :git => "https://github.com/db-in/fusion.git", :tag => "#{s.name}-v#{s.version}", :submodules => true }
  
  s.swift_version = '5.0'
  s.requires_arc = true
  s.osx.deployment_target = '12.0'
  s.ios.deployment_target = '15.0'
  s.tvos.deployment_target = '15.0'
  s.watchos.deployment_target = '9.0'
  s.user_target_xcconfig = { 'GENERATE_INFOPLIST_FILE' => 'YES', 'MARKETING_VERSION' => "#{s.version}" }
  s.pod_target_xcconfig = { 'GENERATE_INFOPLIST_FILE' => 'YES', 'MARKETING_VERSION' => "#{s.version}"  }
  
  s.subspec 'Core' do |co|
	  co.public_header_files = 'Fusion/Core/**/*.h'
	  co.source_files = 'Fusion/Core/**/*.{h,m,swift}'
	  co.frameworks = 'Foundation'
	  co.frameworks = 'Security'
	  co.frameworks = 'CommonCrypto'
	  co.frameworks = 'UserNotifications'
  end

  s.subspec 'UI' do |ui|
	  ui.public_header_files = 'Fusion/UI/**/*.h'
	  ui.source_files = 'Fusion/UI/**/*.{h,m,swift}'
#	  ui.resources = 'Fusion/UI/**/*.{xib,xcassets,ttf,storyboard,json,lproj}'
	  ui.dependency 'Fusion/Core'
	  ui.ios.frameworks = 'UIKit'
	  ui.watchos.frameworks = 'UIKit'
	  ui.tvos.frameworks = 'UIKit'
  end
end
