require_relative 'test_helper'

class FileReaderTest < Minitest::Test
  def test_can_read_file_with_no_skip
    first, last = read_first_and_last_lines(skip_top_lines: 0, skip_bottom_lines: 0)

    assert_equal '11111', first
    assert_equal '66666', last
  end

  def test_can_read_file_with_skip_top_only
    first, last = read_first_and_last_lines(skip_top_lines: 1, skip_bottom_lines: 0)

    assert_equal '22222', first
    assert_equal '66666', last
  end

  def test_can_read_file_with_skip_bottom_only
    first, last = read_first_and_last_lines(skip_top_lines: 0, skip_bottom_lines: 1)

    assert_equal '11111', first
    assert_equal '55555', last
  end

  def test_can_read_file_with_skip_1
    first, last = read_first_and_last_lines(skip_top_lines: 1, skip_bottom_lines: 1)

    assert_equal '22222', first
    assert_equal '55555', last
  end

  def test_can_read_file_with_skip_2
    first, last = read_first_and_last_lines(skip_top_lines: 2, skip_bottom_lines: 2)

    assert_equal '33333', first
    assert_equal '44444', last
  end

  def test_can_read_file_with_skip_top_bottom_covers_all
    first, _last = read_first_and_last_lines(skip_top_lines: 3, skip_bottom_lines: 3)

    assert_nil first
  end

  def test_can_read_file_with_skip_top_bottom_overlap
    first, _last = read_first_and_last_lines(skip_top_lines: 4, skip_bottom_lines: 3)

    assert_nil first
  end

  def test_can_read_file_with_skip_top_bigger_than_file
    first, _last = read_first_and_last_lines(skip_top_lines: 10, skip_bottom_lines: 0)

    assert_nil first
  end

  def test_can_read_file_with_skip_bottom_bigger_than_file
    first, _last = read_first_and_last_lines(skip_top_lines: 0, skip_bottom_lines: 10)

    assert_nil first
  end

  def test_can_read_file_with_skip_top_and_bottom_bigger_than_file
    first, _last = read_first_and_last_lines(skip_top_lines: 10, skip_bottom_lines: 10)

    assert_nil first
  end

  def test_can_parse_sample_data_file
    format = FixedWidthFileValidator::FileFormat.for(:test_format_1, 'test/data/sample_format_1.yml')
    reader = format.create_file_reader('test/data/test_data_1.txt')
    records = []
    reader.each_record { |record| records << record }

    assert records.size == 3
    assert records.first[:_line_num] == 2
    assert records.first[:name] == 'LI LIN'
  end

  private

  def read_first_and_last_lines(settings)
    sample_data = %(11111
22222
33333
44444
55555
66666
)
    first_line = nil
    last_line = nil
    with_tmp_file_from_string(sample_data) do |data_file_path|
      reader = FixedWidthFileValidator::FileReader.new(data_file_path, nil, settings)
      reader.each_record do |line|
        first_line = line if first_line.nil?
        last_line = line
      end
    end
    [first_line, last_line]
  end
end
