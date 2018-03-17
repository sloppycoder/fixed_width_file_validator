# rubocop:disable Metrics/AbcSize

require_relative 'test_helper'

class FixedWidthFileValidatorTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::FixedWidthFileValidator::VERSION
  end

  def test_can_parse_sample_file
    validator = FixedWidthFileValidator::Validator.new('test/data/sample_rule_1.yml', :some_file_format)
    result = validator.validate('test/data/test_data_1.txt')

    assert validator.parser.field_list.count == 5
    assert result.count == 3
    assert validator.non_unique_values.keys.include? :phone
    assert result[0][:validation] == 'unique' && result[1][:validation] == 'unique'
    assert result[2][:error_field_value] == 'DD'
  end
end

# rubocop:enable Metrics/AbcSize
