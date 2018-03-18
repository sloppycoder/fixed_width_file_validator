require_relative 'test_helper'

class FieldValidatorTest < Minitest::Test
  def test_can_validate_string_methods
    assert validate_simple_value(['not_blank', 'width 3'], 'abc').empty?
    assert validate_simple_value(['blank'], '').empty?
  end

  def test_can_validate_string_matches
    assert validate_simple_value(['mama'], 'mama').empty?
    refute validate_simple_value(['mama'], 'mama mia').empty?
  end

  def test_can_validate_string_in_list
    assert validate_simple_value([['A', 'BB', 'CCC']], 'BB').empty?
    refute validate_simple_value([['A', 'BB', 'CCC']], 'DDDD').empty?
  end

  def test_can_validate_date_time
    assert validate_simple_value(['date'], '20180318').empty?
    refute validate_simple_value(['date'], '20183224').empty?

    assert validate_simple_value(['time'], '201823').empty?
    refute validate_simple_value(['time'], '201865').empty?
  end

  def test_can_validate_lambda
    assert validate_simple_value(['^ to_i > 100'], '101').empty?
    assert validate_simple_value(['^ slice(0..0) == "S" && slice(1..-1) == "CB" '], 'SCB').empty?
  end

  def test_can_validate_lambda_with_record
    validations = ['^ include? r[:name]']
    record1 = { name: 'LI LIN', full_name: 'LI LIN THE GEEK' }
    record2 = { name: 'MISTER Felix', full_name: 'nobody knows' }

    assert validate_record(validations, record1, :full_name).empty?
    refute validate_record(validations, record2, :full_name).empty?
  end

  private

  def validate_simple_value(validations, value)
    validator = FixedWidthFileValidator::FieldValidator.new(:test_record, :value, validations)
    validator.validate({ value: value }, :value)
  end

  def validate_record(validations, record, field_name)
    validator = FixedWidthFileValidator::FieldValidator.new(:test_record, field_name, validations)
    validator.validate(record, field_name)
  end
end
