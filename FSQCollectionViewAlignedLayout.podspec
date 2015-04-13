Pod::Spec.new do |s|
  s.name      = 'FSQCollectionViewAlignedLayout'
  s.version   = '1.1.1'
  s.platform  = :ios
  s.summary   = 'A simple, generic collection view layout with multiple customization options.'
  s.homepage  = 'https://github.com/foursquare/FSQCollectionViewAlignedLayout'
  s.license   = { :type => 'Apache', :file => 'LICENSE.txt' }
  s.authors   = { 'Brian Dorfman' => 'https://twitter.com/bdorfman',
                  'Cameron Mulhern' => 'http://www.cameronmulhern.com'}
  s.source    = { :git => 'https://github.com/foursquare/FSQCollectionViewAlignedLayout.git',
                  :tag => "v#{s.version}" }
  s.source_files  = '*.{h,m}'
  s.requires_arc  = true
end
