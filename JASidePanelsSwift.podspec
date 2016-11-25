#
# Be sure to run `pod lib lint JASidePanelsSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JASidePanelsSwift'
  s.version          = '2.0.1'
  s.summary          = 'JASidePanels Swift SideMenu'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/manikad24/JASidePanelsSwift'
  s.screenshots     = 'https://s16.postimg.org/ld2d4y0h1/Simulator_Screen_Shot_17_Nov_2016_3_49_46_PM.png', 'https://s4.postimg.org/fftbb7m5p/Simulator_Screen_Shot_17_Nov_2016_3_49_42_PM.png'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Manikandan' => 'manikad24@gmail.com' }
  s.source           = { :git => 'https://github.com/manikad24/JASidePanelsSwift.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/manikad24'

  s.ios.deployment_target = '8.0'

  s.source_files = 'JASidePanelsSwift/Classes/**/*'
  
  # s.resource_bundles = {
  #   'JASidePanelsSwift' => ['JASidePanelsSwift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
