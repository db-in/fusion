Pod::Spec.new do |s|
  s.name = "Fusion"
  s.version = "1.1.15"
  s.summary = 'A generic self encaptulated framework for all purpose projects'
  s.description = <<-DESC
  A generic self encaptulated framework for all purpose projects
                  DESC
  s.homepage = 'https://fusion.com'
  s.documentation_url = 'https://db-in.github.io/fusion/'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = 'Diney Bomfim'
  s.source = { :git => "git@github.com:db-in/fusion.git", :tag => "#{s.name}-v#{s.version}", :submodules => true }
  
  s.requires_arc = true
  s.swift_version = '5.0'
  s.osx.deployment_target = '11.0'
  s.ios.deployment_target = '13.0'
  s.tvos.deployment_target = '13.0'
  s.watchos.deployment_target = '7.0'
  s.user_target_xcconfig = { 'CODE_SIGNING_REQUIRED' => 'NO', 'EXPANDED_CODE_SIGN_IDENTITY' => "" }
  s.pod_target_xcconfig = { 'CODE_SIGNING_ALLOWED' => 'NO', 'EXPANDED_CODE_SIGN_IDENTITY' => "" }
#  s.user_target_xcconfig = { 'GENERATE_INFOPLIST_FILE' => 'YES' }
#  s.pod_target_xcconfig = { 'GENERATE_INFOPLIST_FILE' => 'YES' }
#  s.info_plist = {
#	  'CFBundleVersion' => "#{s.version}",
#	  'CFBundleShortVersionString' => "#{s.version}"
#  }
  
  s.subspec 'Core' do |co|
	  co.public_header_files = 'Fusion/Core/**/*.h'
	  co.source_files = 'Fusion/Core/**/*.{h,m,swift}'
	  co.frameworks = ['Foundation', 'Security', 'CommonCrypto', 'UserNotifications']
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
