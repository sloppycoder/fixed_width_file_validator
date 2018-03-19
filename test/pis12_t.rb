require_relative 'test_helper'

class RuleParserTest < Minitest::Test
  def test_can_parse_tandem_sample_file
    data_file_path = 'test/data/PIS12TWTDEM09042017140418.txt'
    format = FixedWidthFileValidator::FileFormat.for(:tandem, 'test/data/pis12.yml')
    reader = format.create_file_reader(data_file_path)
    validator = format.create_record_validator_with_reader(data_file_path)

    errors = validator.find_all_errors(reader)
    other_errors = errors.reject { |r| r.failed_validation == 'unique' }
    assert_equal 4, other_errors.count
  end

  def test_can_parse_c400_sample_file
    skip
    puts "Start: #{Time.now}"
    data_file_path = '/Users/lee/tmp/CRTRAN25AEC40012052017193043.txt'
    format = FixedWidthFileValidator::FileFormat.for(:tandem, 'test/data/pis12.yml')
    reader = format.create_file_reader(data_file_path)
    validator = format.create_record_validator_with_reader(data_file_path)
    errors = validator.find_all_errors(reader)
    puts "End: #{Time.now}"

    assert errors.count
  end
end
