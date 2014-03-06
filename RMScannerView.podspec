Pod::Spec.new do |s|
  s.name     = 'RMScannerView'
  s.version  = '1.3'
  s.platform = :ios, '7.0'
  s.license  = 'MIT'
  s.summary  = 'Simple barcode scanner UIView subclass for iOS apps.'
  s.homepage = 'https://github.com/iRareMedia/RMScannerView'
  s.author   = { 'Sam Spencer' => 'contact@iraremedia.com' }
  s.source   = { :git => 'https://github.com/iRareMedia/RMScannerView.git', :tag => s.version.to_s }

  s.description = 'Simple barcode scanner UIView subclass for iOS apps. ' \
                  'Quickly and efficiently scans a large variety of barcodes ' \
                  'using the iOS device\'s built in camera. '

  s.frameworks   = ['AVFoundation', 'CoreGraphics']
  s.source_files = 'RMScannerView/*.{h,m}'
  s.preserve_paths  = 'Scanner App'
  s.requires_arc = true
end
