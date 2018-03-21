if ENV['COVERAGE'] == '1'
  require 'simplecov'
  SimpleCov.start do
    add_filter %r{^/test/}
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'fixed_width_file_validator'

if RUBY_PLATFORM == 'java'
  require 'pry'
  require 'pry-debugger-jruby'
else
  require 'byebug'
end

require 'minitest/autorun'
require 'tempfile'

def with_tmp_file_from_string(content)
  tmp_file = Tempfile.new('fixed_width_file_validator_test')
  tmp_file.write(content)
  tmp_file.close

  yield tmp_file.path

  tmp_file.unlink
end
