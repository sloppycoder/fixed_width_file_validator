require_relative 'test_helper'

class RecordFormatterTest < Minitest::Test
  def test_can_calculate_record_width
    formatter = test_formatter

    assert_equal 40, formatter.record_width
  end

  def test_can_format_simple_record
    test_record = { id: 100, sex: 'M', age: 48, name: 'felix m. bath' }

    formatter = test_formatter
    output = formatter.string_for(test_record)

    assert_equal formatter.record_width, output.length
    assert_equal '  100M      48             felix m. bath', output
  end

  def test_can_format_bad_record
    test_record = {
      id: nil,          # nil value will be white spaces in output
      sex: 'TOO_LARGE', # longer than width, the right most characters will be truncated
      age: 1_234_567,   # integer value larger width, right most digits will be truncated
      name: 'this',     # value is shorter than width, space will be padded to the left
    }

    formatter = test_formatter
    output = formatter.string_for(test_record)

    assert_equal formatter.record_width, output.length
    assert_equal '     T   123456                     this', output
  end

  private

  def test_formatter
    FixedWidthFileValidator::RecordFormatter.new([
                                                   { position: 1, width: 5, name: :id, format: '%5d' },
                                                   { position: 6, width: 1, name: :sex, format: '%s' },
                                                   # size in format string is less than field width
                                                   # there is a gap between the position of the following
                                                   # field and the previous field
                                                   { position: 10, width: 6, name: :age, format: '%-03s' },
                                                   { position: 16, width: 25, name: :name, format: '%s' }
                                                 ])
  end
end
