require_relative 'test_helper'
require_relative 'string_helper_test'
require_relative 'field_validator_test'
require_relative 'file_reader_test'
require_relative 'file_format_config_test'

class FixedWidthFileValidatorTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::FixedWidthFileValidator::VERSION
  end
end
