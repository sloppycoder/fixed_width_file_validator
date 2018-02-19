require_relative 'test_helper'

class RuleParserTest < Minitest::Test
  def test_fields_from_common_get_merged
    validator = FixedWidthFileValidator::Validator.new('test/data/pis12.yml', :hogan)
    assert validator.rule.rules.include?(:aip_dynamic)
    assert validator.rule.rules[:chip_spec_version][:starts_at] == '442'
  end
end
