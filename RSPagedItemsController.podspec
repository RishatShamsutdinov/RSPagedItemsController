Pod::Spec.new do |s|
  s.name         = "RSPagedItemsController"
  s.version      = "3.1.0"
  s.summary      = "No summary yet."

  s.description  = <<-DESC
                   No description yet.
                   DESC

  s.homepage     = "https://github.com/RishatShamsutdinov/RSPagedItemsController"

  s.license      = "Apache License, Version 2.0"

  s.author       = { "Rishat Shamsutdinov" => "dichat.dark@gmail.com" }

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/RishatShamsutdinov/RSPagedItemsController.git", :tag => "v" + s.version.to_s }

  s.source_files = "RSPagedItemsController/**/*.{h,m}"
  s.private_header_files = "RSPagedItemsController/**/*_Private.h"

  s.framework  = "UIKit"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  s.requires_arc = true

  s.dependency "RSFoundationUtils", "~> 0.1"

end
