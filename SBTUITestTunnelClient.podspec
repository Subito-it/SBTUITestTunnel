Pod::Spec.new do |s|
  s.name = "SBTUITestTunnelClient"
  s.version = "11.0.0"
  s.summary = "Enable network mocks and more in UI Tests"

  s.description = <<-DESC
    Use this library to easily setup an HTTP tunnel between our UI Tests cases and the app under test.
    The tunnel allows to inject data in order to enabale network mocking.
    DESC

  s.homepage = "https://github.com/Subito-it/SBTUITestTunnel"
  s.license = "Apache License, Version 2.0"
  s.author = { "Tomas Camin" => "tomas.camin@adevinta.com" }
  s.source = { :git => "https://github.com/Subito-it/SBTUITestTunnel.git", :tag => s.version.to_s }

  s.ios.deployment_target = "12.0"
  s.tvos.deployment_target = "12.0"
  s.swift_version = "5.0"
  s.requires_arc = true
  s.xcconfig = { "OTHER_LDFLAGS" => "-ObjC" }
  s.pod_target_xcconfig = { :prebuild_configuration => "debug", "ENABLE_BITCODE" => "NO" } # XCTest requires bitcode to be disabled
  s.library = "z"
  s.static_framework = true

  s.frameworks = "XCTest"
  s.source_files = "Sources/SBTUITestTunnelClient/**/*.{h,m}"

  s.dependency "SBTUITestTunnelCommon", "#{s.version}"
end
