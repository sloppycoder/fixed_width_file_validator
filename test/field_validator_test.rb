require_relative 'test_helper'

class FieldValidatorTest < Minitest::Test
  def test_validation_errors
    value = 'abcdef'
    errors = validate_simple_value(['not_blank', 'width 3', 'numeric'], value)
    assert_equal 2, errors.size
    assert_instance_of  FixedWidthFileValidator::FieldValidationError, errors.first
    assert_equal value, errors.first.failed_value
  end

  def test_can_validate_string_methods
    assert_empty validate_simple_value(['not_blank', 'width 3'], 'abc')
    assert_empty validate_simple_value(['blank'], '')
  end

  def test_can_validate_string_matches
    assert_empty validate_simple_value(['mama'], 'mama')
    refute_empty validate_simple_value(['mama'], 'mama mia')
  end

  # rubocop:disable Style/WordArray
  def test_can_validate_string_in_list
    assert_empty validate_simple_value([['A', 'BB', 'CCC']], 'BB')
    refute_empty validate_simple_value([['A', 'BB', 'CCC']], 'DDDD')
  end
  # rubocop:enable Style/WordArray

  def test_can_validate_date_time
    assert_empty validate_simple_value(['date'], '20180318')
    refute_empty validate_simple_value(['date'], '20183224')

    assert_empty validate_simple_value(['time'], '201823')
    refute_empty validate_simple_value(['time'], '201865')
  end

  def test_can_validate_lambda
    assert_empty validate_simple_value(['^ to_i > 100'], '101')
    assert_empty validate_simple_value(['^ slice(0..0) == "S" && slice(1..-1) == "CB" '], 'SCB')
  end

  def test_can_validate_lambda_with_binding
    bindings = { val: 100, country: 'MY' }
    assert_empty validate_simple_value(['^ to_i > _g[:val]'], '101', bindings)
    assert_empty validate_simple_value(['^ slice(0..1) == _g[:country]'], 'MYSG123', bindings)
  end

  def test_can_validate_lambda_with_record
    validations = ['^ include? r[:name]']
    record1 = { name: 'LI LIN', full_name: 'LI LIN THE GEEK' }
    record2 = { name: 'MISTER Felix', full_name: 'nobody knows' }

    assert_empty validate_record(validations, record1, :full_name)
    refute_empty validate_record(validations, record2, :full_name)
  end

  private

  def validate_simple_value(validations, value, bindings = {})
    validator = FixedWidthFileValidator::FieldValidator.new(:value, 1, 1, validations)
    validator.validate({ value: value }, :value, bindings)
  end

  def validate_record(validations, record, field_name, bindings = {})
    validator = FixedWidthFileValidator::FieldValidator.new(field_name, 1, 1, validations)
    validator.validate(record, field_name, bindings)
  end
end
