require_relative 'test_helper'

class RuleParserTest < Minitest::Test
  def test_fields_from_common_get_merged
    validator = FixedWidthFileValidator::Validator.new('test/data/pis12.yml', :tandem)
    assert validator.rule.rules.include?(:aip_dynamic)
    assert validator.rule.rules[:chip_spec_version][:start_column] == 441
  end

  def test_can_parse_tandem_sample_file
    validator = FixedWidthFileValidator::Validator.new('test/data/pis12.yml', :tandem)

    result = validator.validate('test/data/PIS12TWTDEM09042017140418.txt')
    other_errors = result.reject { |r| r[:validation] == 'unique' }
    assert other_errors.count == 4
  end

  def test_can_parse_c400_sample_file
    skip
    puts "Start: #{Time.now}"
    validator = FixedWidthFileValidator::Validator.new('test/data/pis12.yml', :c400)
    result = validator.validate('/Users/lee/tmp/CRTRAN25AEC40012052017193043.txt')
    puts "End: #{Time.now}"

    puts result.count
  end
end
