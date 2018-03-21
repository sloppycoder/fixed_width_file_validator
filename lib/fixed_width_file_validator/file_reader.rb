module FixedWidthFileValidator
  class FileReader
    def initialize(file_name, parser = nil, settings = {})
      @skip_top_lines = settings[:skip_top_lines] || 0
      @skip_bottom_lines = settings[:skip_bottom_lines] || 0
      @data_file_path = file_name
      @line_num = 0
      @buffer = []
      @parser = parser
      @skip_top_done = false
    end

    def next_record
      line_num, content = readline_with_skip
      return unless line_num
      @parser ? @parser.parse(content, line_num, content) : content.strip
    end

    def each_record
      record = next_record
      until record.nil?
        # puts "#{Time.now} at #{@line_num}" if @line_num % 10000 == 0
        yield record
        record = next_record
      end
    ensure
      close
    end

    def close
      @file&.close
    ensure
      @file = nil
    end

    def find_non_unique_values(field_list = [])
      return if field_list.empty?

      lookup_hash = build_unique_value_lookup_hash(field_list)

      result = {}
      field_list.each do |field_name|
        result[field_name] = lookup_hash[field_name].select { |_k, v| v.count > 1 }
      end
      result
    end

    private

    def readline_with_skip
      @file ||= File.open(@data_file_path, 'r')
      skip_top
      skip_bottom
      readline
    end

    def readline
      return nil if @file.eof?

      buffer_line
      @buffer.shift
    end

    def next_line
      return nil if @file.eof?
      @line_num += 1
      [@line_num, @file.readline]
    end

    def buffer_line
      return nil if @file.eof?
      @buffer << next_line
    end

    def skip_top
      return if @skip_top_done

      @skip_top_lines.times { next_line }
      @skip_top_done = true
    end

    def skip_bottom
      @skip_bottom_lines.times { buffer_line } if @buffer.empty?
    end

    def build_unique_value_lookup_hash(field_list)
      tmp_store = {}

      each_record do |record|
        field_list.each do |field_name|
          tmp_store[field_name] ||= {}
          tmp_store[field_name][record[field_name]] ||= []
          tmp_store[field_name][record[field_name]] << @line_num
        end
      end

      tmp_store
    end
  end
end
