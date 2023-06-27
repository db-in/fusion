Pod::Spec.new do |s|
  s.name = "Fusion"
  s.version = "1.0.6"
  s.summary = "Micro Feature"
  s.description = <<-DESC
                  Fusion is resposible for ...
                  DESC
  s.homepage = "https://fusion.com"
  s.documentation_url = "https://db-in.github.io/fusion/"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = 'Diney Bomfim'
  s.source = { :git => "git@github.com:db-in/fusion.git", :tag => "#{s.name}-v#{s.version}", :submodules => true }
  
  s.swift_version = '5.0'
  s.requires_arc = true
  s.user_target_xcconfig = { 'GENERATE_INFOPLIST_FILE' => 'YES' }
  s.pod_target_xcconfig = { 'GENERATE_INFOPLIST_FILE' => 'YES' }
  
  s.subspec 'Core' do |co|
	  s.ios.deployment_target = '13.0'
	  s.osx.deployment_target = '11.0'
	  s.tvos.deployment_target = '13.0'
	  s.watchos.deployment_target = '7.0'
	  co.public_header_files = 'Fusion/Core/**/*.h'
	  co.source_files = 'Fusion/Core/**/*.{h,m,swift}'
	  co.frameworks = 'Foundation'
	  co.frameworks = 'Security'
	  co.frameworks = 'CommonCrypto'
	  co.frameworks = 'UserNotifications'
  end

  s.subspec 'UI' do |ui|
	  s.ios.deployment_target = '13.0'
	  s.tvos.deployment_target = '13.0'
	  s.watchos.deployment_target = '7.0'
	  ui.public_header_files = 'Fusion/UI/**/*.h'
	  ui.source_files = 'Fusion/UI/**/*.{h,m,swift}'
	  ui.resources = 'Fusion/UI/**/*.{xib,xcassets,ttf,storyboard,json,lproj}'
	  ui.dependency 'Fusion/Core'
	  ui.ios.frameworks = 'UIKit'
	  ui.watchos.frameworks = 'UIKit'
	  ui.tvos.frameworks = 'UIKit'
  end
end
