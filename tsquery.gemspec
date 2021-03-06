# frozen_string_literal: true
Gem::Specification.new do |s|
  s.name          = 'tsquery'
  s.version       = '2.0.3'
  s.required_ruby_version = '>= 2.2.0'
  s.authors       = ['Mario Uher']
  s.email         = ['uher.mario@gmail.com']
  s.summary       = 'Automate your TeamSpeak3 server with Ruby!'
  s.homepage      = 'https://github.com/tsjoin/tsquery'
  s.license       = 'MIT'

  s.files         = Dir['lib/*.rb']
  s.test_files    = Dir['test/*_test.rb']
  s.require_paths = ['lib']

  s.add_development_dependency 'bundler', '~> 1.7'
  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rubocop', '~> 0.40'
end
