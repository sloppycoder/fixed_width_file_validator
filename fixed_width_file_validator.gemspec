
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fixed_width_file_validator/version'

Gem::Specification.new do |spec|
  spec.name          = 'fixed_width_file_validator'
  spec.version       = FixedWidthFileValidator::VERSION
  spec.authors       = ['Li Lin']
  spec.email         = ['guru.lin@gmail.com']

  spec.summary       = 'validate fixed width text file base on configuration'
  spec.description   = 'validate fixed width text file base on configuration'
  spec.homepage      = 'https://github.com/sloppycoder/fixed_width_file_validator.git'
  spec.license       = 'MIT'

  spec.files = Dir[
    'README.md',
    'lib/**/*'
  ]

  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 10.0'
end
