#!/usr/bin/env ruby

module Build
    EXAMPLE_APP_SCHEME = "SBTUITestTunnel_Example"
    UITESTS_SCHEME = "SBTUITestTunnel_Tests"
    UITESTS_NOSWIZZ_SCHEME = "SBTUITestTunnel_TestsNoSwizzling"

    def self.run_build() 
        puts "⏳ Building app..."
        return run_xcodebuild("clean build analyze", EXAMPLE_APP_SCHEME)
    end

    def self.run_ui_tests() 
        puts "⏳ Run UITests..."
        return run_xcodebuild("test", UITESTS_SCHEME)
    end

    def self.run_ui_tests_no_swizzling() 
        puts "⏳ Run UITests with no swizzling..."
        return run_xcodebuild("test", UITESTS_NOSWIZZ_SCHEME)
    end

    def self.run_xcodebuild(action,schemeName)
        base_path = `git rev-parse --show-toplevel`.strip
        workspace = "#{base_path}/Example/SBTUITestTunnel.xcworkspace"
        destination = make_destination()
        command = "xcodebuild #{action} -scheme #{schemeName} -workspace #{workspace} -retry-tests-on-failure -destination \"#{destination}\" | xcpretty && exit ${PIPESTATUS[0]}"
        result = system(command)
        if result
            puts "XcodeBuild status: ✅ SUCCESS"
        else
            puts "XcodeBuild status: 🚨 FAILED"
        end
        return result
    end 

    def self.make_destination()
        platform = "iOS Simulator"
        device = available_simulators()
        destination = "platform=#{platform},name=#{device}"
        return destination
    end

    def self.available_simulators()
        device=`xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | awk '{$1=$1;print}' | sed -e "s/ Simulator$//"`.strip
        return device
    end
end