Pod::Spec.new do |s|
    s.name             = "SBTUITestTunnelClient"
    s.version          = "4.0.0"
    s.summary          = "Enable network mocks and more in UI Tests"

    s.description      = <<-DESC
    This is library for UI tests target.

    Use this library to easily setup an HTTP tunnel between our UI Tests cases and the app under test.
    The tunnel allows to inject data in order to enabale network mocking.
    DESC

    s.homepage         = "https://github.com/Subito-it/SBTUITestTunnel"
    s.license          = 'Apache License, Version 2.0'
    s.author           = { "Tomas Camin" => "tomas.camin@adevinta.com" }
    s.source           = { :git => "https://github.com/Subito-it/SBTUITestTunnel.git", :tag => s.version.to_s }

    s.platform = :ios, '9.0'
    s.requires_arc = true
    s.static_framework = true
    s.xcconfig = { "OTHER_LDFLAGS" => "-ObjC" }
    s.pod_target_xcconfig = { :prebuild_configuration => 'debug' }
    s.library = 'z'

    s.source_files = 'Pod/Client/*.{h,m}'

    s.dependency 'SBTUITestTunnelCommon'  

    s.framework = "XCTest"
    s.user_target_xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '$(PLATFORM_DIR)/Developer/Library/Frameworks' }
end
