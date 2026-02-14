source 'https://cdn.cocoapods.org/'

inhibit_all_warnings!
use_frameworks!
platform :ios, '15.0'
workspace 'Fusion.xcworkspace'

def local
	pod 'LocalServer'
	pod 'Fusion', :path => './'
end
	
target 'FusionTests' do
	project 'Fusion'
	local
end

target 'Sample iOS' do
	project 'Fusion'
	local
end

target 'Sample macOS' do
	project 'Fusion'
	local
end

target 'Sample tvOS' do
	project 'Fusion'
	local
end
