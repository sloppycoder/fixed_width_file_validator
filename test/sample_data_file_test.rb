require_relative 'test_helper'

class SampleDataFileTest < Minitest::Test
  def test_can_parse_sample_data_file
    format = FixedWidthFileValidator::FileFormat.for(:test_format_1, 'test/data/sample_format_1.yml')
    reader = format.create_file_reader('test/data/test_data_1.txt')
    validator = format.create_record_validator_with_reader('test/data/test_data_1.txt')
    validator.bindings = { secret: 'XYZ' }

    errors = validator.find_all_errors(reader)
    other_errors = errors.reject { |r| r.failed_validation == 'unique' }
    unique_errors = errors.select { |r| r.failed_validation == 'unique' }

    # formatter = FixedWidthFileValidator::TextReportFormatter.new
    # errors.each { |err| formatter.write(err) } unless errors.empty?
    # formatter.write_unique_errors(unique_errors) unless unique_errors.empty?

    assert_equal 1, other_errors.size
    assert_equal '60311223344', unique_errors.first.failed_value
  end
end
