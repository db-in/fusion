source 'https://cdn.cocoapods.org/'

inhibit_all_warnings!
use_frameworks!
platform :ios, '13.0'
workspace 'Fusion.xcworkspace'

target 'FusionTests' do
	project 'Fusion'
	pod 'LocalServer'
	pod 'Fusion', :path => './'
end

target 'Sample iOS' do
	project 'Fusion'
	pod 'LocalServer'
	pod 'Fusion', :path => './'
end

#target 'Sample macOS' do
#	project 'Fusion'
#	pod 'LocalServer'
#	pod 'Fusion', :path => './'
#end
#
#target 'Sample tvOS' do
#	project 'Fusion'
#	pod 'LocalServer'
#	pod 'Fusion', :path => './'
#end
