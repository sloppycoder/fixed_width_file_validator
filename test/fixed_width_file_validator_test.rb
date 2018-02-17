# rubocop:disable Metrics/AbcSize

require 'test_helper'

class FixedWidthFileValidatorTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::FixedWidthFileValidator::VERSION
  end

  def test_can_parse_sample_file
    validator = FixedWidthFileValidator::Validator.new('test/data/sample_rule_1.yml', :some_file_format)
    assert validator.parser.field_list.count == 3

    result = validator.validate('test/data/test_data_1.txt')
    assert result.count == 2
    assert validator.non_unique_values.keys.include? :phone
    assert result[0][:validation] == 'unique' && result[1][:validation] == 'unique'
  end

  def test_string_helper
    assert t('').any
    assert t('').blank
    refute t('').not_blank
    assert t('   ABC DEF ABC DEF').right_justified
    assert t('ABC DEF ABC DEF    ').left_justified
    assert t('1000').numeric
    assert t('1000.').numeric
    refute t('1000.11').numeric
    assert t('1000.11').numeric(2)
    assert t('').width(0)
    assert t('ABCC DEF').width(8)
  end

  private

  def t(test_str)
    test_str.extend(FixedWidthFileValidator::StringHelper)
  end
end

# rubocop:enable Metrics/AbcSize
