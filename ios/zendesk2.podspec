#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint zendesk2.podspec' to validate before publishing.
#
# https://cocoapods.org/pods/ZendeskChatProvidersSDK
# https://cocoapods.org/pods/ZendeskAnswerBotProvidersSDK
Pod::Spec.new do |s|
  s.name             = 'zendesk2'
  s.version          = '0.0.1'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'ZendeskCoreSDK', '~>2.5.1'
  s.dependency 'ZendeskChatProvidersSDK', '~>2.11.1'
  s.dependency 'ZendeskAnswerBotProvidersSDK', '~> 2.1.3'
  s.platform = :ios, '10.0'
  s.requires_arc = true
  s.swift_version = '5.3.2'
  s.cocoapods_version = '>= 1.10.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
