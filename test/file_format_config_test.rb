require_relative 'test_helper'

class FileFormatConfigurationTest < Minitest::Test
  def test_can_parse_sample_file
    format = FixedWidthFileValidator::FileFormat.for(:test_format_1, 'test/data/sample_rule_1.yml')

    total_fields = 5
    assert format.fields.size == total_fields # inherit_from works
    assert format.record_parser.field_list.size == total_fields
    assert format.field_validations(:phone).include? 'unique'
    assert format.field_validations(:field_66).is_a? Array
    assert format.field_validations(:non_existent).nil?
  end
end
