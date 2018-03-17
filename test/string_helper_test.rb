# rubocop:disable Metrics/AbcSize

require_relative 'test_helper'

class StringHelperTest < Minitest::Test
  def test_string_helper
    assert ''.any

    assert ''.blank
    refute ''.not_blank

    # numeric(max_length=32, precision=0, min_length=1)
    assert '1000'.numeric
    refute '1000'.numeric(3)
    assert '1000.'.numeric
    assert '1000.'.numeric(5, 0, 4)
    refute '1000.'.numeric(3, 0, 2)
    refute '1000.11'.numeric
    assert '1000.11'.numeric(4, 2)
    assert '0000'.numeric
    refute ''.numeric
    refute 'abc'.numeric

    assert ''.width(0)
    assert 'ABCC DEF'.width(8)

    assert ''.numeric_or_blank
    refute 'X'.numeric_or_blank

    assert '20100101'.date
    refute '20102301'.date
    refute '2300'.date

    assert '12312010'.date '%m%d%Y'
    refute '13312010'.date '%m%d%Y'

    assert '000000'.time
    assert '120259'.time
    refute '120260'.time

    assert '20100101010101'.date_time
    refute '20102301260101'.date_time
    refute '2010230126010112'.date_time
  end
end

# rubocop:enable Metrics/AbcSize
