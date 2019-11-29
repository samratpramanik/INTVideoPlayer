
Pod::Spec.new do |spec|

  spec.name         = "INTVideoPlayer"
  spec.version      = "1.0.0"
  spec.summary      = "It's a full screen video player with custom controller"
  spec.description  = <<-DESC
                        This video player help you build simple and atractive video player for your application
                        DESC
  spec.homepage     = "https://github.com/samratpramanik/INTVideoPlayer"
  spec.license      = "MIT"
  spec.author             = { "Samrat Pramanik" => "samrat.pramanik@indusnet.co.in" }
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/samratpramanik/INTVideoPlayer.git", :tag => "1.0.0" }
  spec.source_files  = "INTVideoPlayer/**/*.{h,m,swift}"
  spec.resource_bundles = { '{podName}' => ['{podName}/Classes/*.xib'] }

an

end