Pod::Spec.new do |s|

  s.name         = "StompClient"
  s.version      = "0.2.6"
  s.summary      = "Simple STOMP client."
  s.description  = "This project is a simple STOMP client, and we use Starscream as a websocket dependency."
  s.homepage     = "https://github.com/ShengHuaWu/StompClient"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "ShengHua Wu" => "fantasy0404@gmail.com" }
  s.social_media_url   = "https://twitter.com/ShengHuaWu"
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/ShengHuaWu/StompClient.git", :tag => "#{s.version}" }
  s.source_files  = "StompClient/*.swift"
  s.requires_arc     = true
  s.dependency "Starscream", "~> 2.0.0"

end
