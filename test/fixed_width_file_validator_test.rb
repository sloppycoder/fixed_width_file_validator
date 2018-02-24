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
    assert t('0000').numeric

    assert t('').width(0)
    assert t('ABCC DEF').width(8)

    assert t('').numeric_or_blank
    refute t('X').numeric_or_blank

    assert t('20100101').date
    refute t('20102301').date
    refute t('2300').date

    assert t('000000').time
    assert t('120259').time
    refute t('120260').time

    assert t('20100101010101').date_time
    refute t('20102301260101').date_time
    refute t('2010230126010112').date_time
  end

  private

  def t(test_str)
    test_str.extend(FixedWidthFileValidator::StringHelper)
  end
end

# rubocop:enable Metrics/AbcSize
