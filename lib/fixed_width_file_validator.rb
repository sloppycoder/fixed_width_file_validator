require 'fixed_width_file_validator/version'
require 'yaml'
require 'date'
require 'time'
require 'ripper'
require 'string_helper'
require 'file_format_config'

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

  class FieldValidationError
    attr_reader :raw, :record, :line_num, :failed_field, :failed_value, :failed_validation

    def initialize(validation, record, field_name)
      @raw = record[:_raw]
      @line_num = record[:_line_num]
      @record = record
      @failed_field = field_name
      @failed_validation = validation
      @failed_value = record[field_name]
    end
  end

  class FieldValidator
    attr_accessor :field_name, :non_unique_values, :validations

    def initialize(field_name, validations = nil)
      self.field_name = field_name
      self.non_unique_values = []
      self.validations = validations
    end

    # return an array of error objects
    # empty array if all validation passes
    def validate(record, field_name, bindings = {})
      if validations
        validations.collect do |validation|
          FieldValidationError.new(validation, record, field_name) unless valid_value?(validation, record, field_name, bindings)
        end.compact
      elsif record && record[field_name]
        # when no validation rules exist for the field, just check if the field exists in the record
        []
      else
        raise "found field value nil in #{record} field #{field_name}, shouldn't be possible?"
      end
    end

    def valid_value?(validation, record, field_name, _bindings)
      value = record[field_name]
      if value.nil?
        false
      elsif validation.is_a? String
        keyword = Ripper.tokenize(validation).first
        if validation == 'unique'
          !non_unique_values.include?(value)
        elsif keyword == '^' || value.respond_to?(keyword)
          validation = validation[1..-1] if keyword == '^'
          code = "lambda { |r| #{validation} }"
          value.instance_eval(code).call(record)
        else
          value == validation
        end
      elsif validation.is_a? Array
        validation.include? value
      else
        raise "Unknown validation #{validation} for #{record_type}/#{field_name}"
      end
    end
  end

  class RecordValidator
    attr_reader :bindings

    def initialize(fields, unique_field_list = nil, reader = nil)
      @field_validators = {}
      @bindings = {}

      non_unique_values = reader.find_non_unique_values(unique_field_list)

      fields.each_key do |field_name|
        @field_validators[field_name] = FieldValidator.new(field_name, fields[field_name][:validations])
        @field_validators[field_name].non_unique_values = non_unique_values[field_name] if unique_field_list.include?(field_name)
      end
    end

    def validate(record)
      errors = @field_validators.collect do |field, validator|
        validator.validate(record, field, @bindings)
      end
      errors.reject(&:empty?)
    end

    def find_all_errors(file_reader)
      errors = []
      file_reader.each_record do |record|
        e = validate(record)
        errors << e unless e.empty?
      end
      errors.flatten
    end
  end

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

  class LogStreamReader
  end
end
