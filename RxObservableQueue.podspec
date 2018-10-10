Pod::Spec.new do |s|
  s.name             = "RxObservableQueue"
  s.version          = "4.2.0"
  s.summary          = "A Library for Queuing from Observable"
  s.homepage         = "https://github.com/notohiro/RxObservableQueue"
  s.license          = 'MIT'
  s.author           = { "Hiroshi Noto" => "notohiro@gmail.com" }
  s.source           = { :git => "https://github.com/notohiro/RxQueue.git", :tag => s.version.to_s }

  s.platform         = :ios, '8.0'
  s.swift_version    = '4.2'

  s.requires_arc     = true
  s.source_files     = 'RxObservableQueue/*'
  s.dependency         'RxSwift'
end
