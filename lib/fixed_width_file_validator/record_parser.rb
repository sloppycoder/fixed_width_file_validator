module FixedWidthFileValidator
  class RecordParser
    attr_reader :field_list, :encoding

    def initialize(field_list, encoding)
      @field_list = field_list
      @encoding = encoding || 'ISO-8859-1'
    end

    def parse(line, line_num, raw_line)
      record = { _line_num: line_num, _raw: raw_line }
      encoded = line.encode(@encoding, 'binary', invalid: :replace, undef: :replace)
      field_list.each do |field|
        record[field[:name].to_sym] = encoded[field[:position]].nil? ? nil : encoded[field[:position]].strip
      end
      record
    end
  end
end
