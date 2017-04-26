
Pod::Spec.new do |s|

  s.name         = "SXScanView"
  s.version      = "0.0.1"
  s.summary      = "easy scan qr code or bar code"

  s.homepage     = "https://github.com/poos/SXScanView"

  s.license      = 'MIT'

  s.author             = { "xiaoR" => "bieshixuan@163.com" }

  s.platform     = :ios, "7.1"

  s.source       = { :git => "https://github.com/poos/SXScanView.git", :tag => s.version.to_s }

  s.source_files  = "SXScanView/SXScanView.{h,m}"
  s.resources = "SXScanView/Resources"
  s.requires_arc = true

end