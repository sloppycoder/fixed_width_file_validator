module FixedWidthFileValidator
  class RecordFormatter
    attr_reader :field_list, :encoding

    def initialize(field_list, encoding = nil)
      @field_list = field_list.sort_by { |a| a[:position] }
      @encoding = encoding || 'ISO-8859-1'
    end

    def record_width
      last_field = @field_list.last
      last_field[:position] + last_field[:width] - 1
    end

    def string_for(record)
      out = ''
      last_pos = 1
      @field_list.each do |field|
        current_pos = field[:position]
        out << ' ' * (current_pos - last_pos)
        out << formatted_value(record[field[:name]], field[:format], field[:width])
        last_pos = current_pos + field[:width]
      end
      out
    end

    private

    # format the string using given format
    # if the result is shorter than width, pad space to the left
    # if the result is longer than width, truncate the last characters
    def formatted_value(value, format, width)
      value_str = value ? format(format, value) : ' ' * width # all space for nil value
      length = value_str.length
      if length > width
        value_str.slice(0..width - 1)
      elsif length < width
        ' ' * (width - length) + value_str
      else
        value_str
      end
    end
  end
end
