Pod::Spec.new do |s|
  s.name         = "RQDatePicker"
  s.version      = "0.0.1"
  s.summary      = "An alternative date picker"

  s.description  = <<-DESC
                    RQDatePicker is an alternative to UIDatePicker. It's goal is
                    to create a more visual way of picking dates/times.
                   DESC

  s.homepage     = "https://github.com/rqueue/RQDatePIcker"
  s.license      = "MIT"
  s.author             = { "Ryan Quan" => "ryanhquan@gmail.com" }
  s.platform     = :ios
  s.source       = { :git => "https://github.com/rqueue/RQDatePIcker.git", :tag => "0.0.1" }
  s.source_files  = "RQDatePicker", "RQDatePicker/**/*.{h,m}"
  s.requires_arc          = true
  # s.public_header_files = "Classes/**/*.h"
  s.dependency "RQVisual", "~> 1.0.2"
end
