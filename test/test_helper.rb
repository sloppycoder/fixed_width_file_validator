if ENV['COVERAGE'] == '1'
  require 'simplecov'
  SimpleCov.start do
    add_filter %r{^/test/}
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'fixed_width_file_validator'
require 'fixed_width_file_validator/string_helper'

if RUBY_PLATFORM == 'java'
  require 'pry'
  require 'pry-debugger-jruby'
else
  require 'byebug'
end

require 'minitest/autorun'
require 'tempfile'
