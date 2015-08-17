Gem::Specification.new do |spec|
  spec.name          = 'tsquery'
  spec.version       = '1.0.0'
  spec.authors       = ['Mario Uher']
  spec.email         = ['uher.mario@gmail.com']
  spec.summary       = %q{Automate your TeamSpeak3 server with Ruby!}
  spec.homepage      = 'https://github.com/tsjoin/tsquery'
  spec.license       = 'MIT'

  spec.files         = Dir['*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 10.0'
end
