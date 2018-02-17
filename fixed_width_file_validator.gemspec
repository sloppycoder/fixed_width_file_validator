
lib = File.expand_path('../lib', __FILE__)
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

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'fixed_width_file_parser', '~> 1.0', '>= 1.0.1'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 10.0'
end
