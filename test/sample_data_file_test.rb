require_relative 'test_helper'

class SampleDataFileTest < Minitest::Test
  def test_can_parse_sample_data_file
    format = FixedWidthFileValidator::FileFormat.for(:test_format_1, 'test/data/sample_format_1.yml')
    reader = format.create_file_reader('test/data/test_data_1.txt')
    validator = format.create_record_validator_with_reader(reader)
    errors = validator.find_all_errors(reader)

    assert_equal 1, errors.size
  end
end
