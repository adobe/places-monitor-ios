Pod::Spec.new do |s|
  s.name         = "ACPPlacesMonitor"
  s.version      = "0.0.3"
  s.summary      = "Places monitor for Adobe Experience Cloud SDK. Written and maintained by Adobe."
  s.description  = <<-DESC
                   The Places monitor provides native geolocation functionality, enabling use of the Places product in the V5 Adobe Experience Cloud SDK.
                   DESC

  s.homepage     = "https://git.corp.adobe.com/dms-mobile/v5-podspecs"

  s.license      = {:type => "Commercial", :text => "Adobe.  All Rights Reserved."}
  s.author       = "Adobe Mobile SDK Team"
  s.source       = { :git => 'git@git.corp.adobe.com:dms-mobile/v5-ios-builds.git', :tag => "v#{s.version}-#{s.name}" }
  s.platform = :ios, "10.0"
  s.requires_arc = true

  s.default_subspec = "iOS"

  s.dependency "ACPCore"
  s.dependency "ACPPlaces"

  s.subspec "iOS" do |ios|
    ios.vendored_libraries = "iOS/libACPPlacesMonitor_iOS.a"
    ios.source_files = "iOS/include/*.h"
    ios.frameworks = "CoreLocation"
  end

end
