# Installation (CocoaPods)

It is strongly suggested to use [cocoapods](https://cocoapods.org) as it is the easiest way to embed the library in your project.

Your Podfile should include the sub project `SBTUITestTunnel/Server` for the app target and `SBTUITestTunnel/Client` for the UI test target.

    use_frameworks!

    target 'APP_TARGET' do
      pod 'SBTUITestTunnel/Server'
      
      target 'UITESTS_TARGET' do
        pod 'SBTUITestTunnel/Client'
      end
    end


## 🔥 Installation issues (_framework not found_)

If you’re using CocoaPods v1.0 and your UI Tests fail to start, you may need to add $(FRAMEWORK_SEARCH_PATHS) to your Runpath Search Paths in the Build Settings of the UI Test target!

# Installation (Manual)

Add files in the *Server* and *Common* folder to your application's target, *Client* and *Common* to the UI test target.
