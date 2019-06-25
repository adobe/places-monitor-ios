Pod::Spec.new do |s|
  s.name         = "ACPPlacesMonitor"
  s.version      = "1.0.2"
  s.summary      = "Places monitor for Adobe Experience Cloud SDK. Written and maintained by Adobe."
  s.description  = <<-DESC
                   The Places monitor provides native geolocation functionality, enabling use of the Places product in the V5 Adobe Experience Cloud SDK.
                   DESC

  s.homepage     = "https://github.com/adobe/ACPPlacesMonitor"

  s.license      = "Apache License, Version 2.0"
  s.author       = "Adobe Experience Platform SDK Team"
  s.source       = { :git => 'https://github.com/adobe/ACPPlacesMonitor.git', :tag => "v#{s.version}-#{s.name}" }
  s.platform = :ios, "10.0"
  s.requires_arc = true

  s.default_subspec = "iOS"

  s.static_framework = true

  s.dependency "ACPCore", ">= 2.3.2"
  s.dependency "ACPPlaces", ">= 1.1.0"

  s.subspec "iOS" do |ios|
    ios.public_header_files = "ACPPlacesMonitor/ACPPlacesMonitor.h"
    ios.source_files = "ACPPlacesMonitor/*.{h,m}"
    ios.frameworks = "CoreLocation"
  end

end
