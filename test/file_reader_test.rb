require_relative 'test_helper'

class FileReaderTest < Minitest::Test
  def test_can_read_file_with_no_skip
    first, last = read_first_and_last_lines(skip_top_lines: 0, skip_bottom_lines: 0)

    assert first == '11111'
    assert last == '66666'
  end

  def test_can_read_file_with_skip_top_only
    first, last = read_first_and_last_lines(skip_top_lines: 1, skip_bottom_lines: 0)

    assert first == '22222'
    assert last == '66666'
  end

  def test_can_read_file_with_skip_bottom_only
    first, last = read_first_and_last_lines(skip_top_lines: 0, skip_bottom_lines: 1)

    assert first == '11111'
    assert last == '55555'
  end

  def test_can_read_file_with_skip_1
    first, last = read_first_and_last_lines(skip_top_lines: 1, skip_bottom_lines: 1)

    assert first == '22222'
    assert last == '55555'
  end

  def test_can_read_file_with_skip_2
    first, last = read_first_and_last_lines(skip_top_lines: 2, skip_bottom_lines: 2)

    assert first == '33333'
    assert last == '44444'
  end

  def test_can_read_file_with_skip_top_bottom_covers_all
    first, _last = read_first_and_last_lines(skip_top_lines: 3, skip_bottom_lines: 3)

    assert first.nil?
  end

  def test_can_read_file_with_skip_top_bottom_overlap
    first, _last = read_first_and_last_lines(skip_top_lines: 4, skip_bottom_lines: 3)

    assert first.nil?
  end

  def test_can_read_file_with_skip_top_bigger_than_file
    first, _last = read_first_and_last_lines(skip_top_lines: 10, skip_bottom_lines: 0)

    assert first.nil?
  end

  def test_can_read_file_with_skip_bottom_bigger_than_file
    first, _last = read_first_and_last_lines(skip_top_lines: 0, skip_bottom_lines: 10)

    assert first.nil?
  end

  def test_can_read_file_with_skip_top_and_bottom_bigger_than_file
    first, _last = read_first_and_last_lines(skip_top_lines: 10, skip_bottom_lines: 10)

    assert first.nil?
  end

  def test_can_parse_sample_data_file
    format = FixedWidthFileValidator::FileFormat.for(:test_format_1, 'test/data/sample_format_1.yml')
    reader = FixedWidthFileValidator::FileReader.new('test/data/test_data_1.txt', format.record_parser, format.file_settings)
    records = []
    reader.each_record { |record| records << record }

    assert records.size == 4
    assert records.first[:_line_num] == 2
    assert records.first[:name] == 'LI LIN'
  end

  private

  def read_first_and_last_lines(settings)
    reader = FixedWidthFileValidator::FileReader.new('test/data/file_reader_test_1.txt', nil, settings)
    first_line, last_line = nil, nil
    reader.each_record do |line|
      first_line = line if first_line.nil?
      last_line = line
    end
    [first_line, last_line]
  end
end
