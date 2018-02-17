$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fixed_width_file_validator'

if RUBY_PLATFORM == 'java'
  require 'pry'
  require 'pry-debugger-jruby'
else
  require 'byebug'
end

require 'minitest/autorun'
