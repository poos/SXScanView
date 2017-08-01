
Pod::Spec.new do |s|

  s.name         = "SXScanView"
  s.version      = "0.2.0"
  s.summary      = "easy scan qr code or bar code"

  s.homepage     = "https://github.com/poos/SXScanView"

  s.license      = 'MIT'

  s.author       = { "xiaoR" => "bieshixuan@163.com" }

  s.platform     = :ios, "7.1"

  s.source       = { :git => "https://github.com/poos/SXScanView.git", :tag => s.version.to_s }

  s.source_files  = "SXScanView/SXScanView.{h,m}"

  s.resources = "SXScanView/Resources.bundle"

  s.requires_arc = true

  s.dependency "TZImagePickerController", "1.8.1"
end
