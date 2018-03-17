require 'fixed_width_file_validator/version'
require 'yaml'
require 'date'
require 'time'
require 'ripper'
require 'string_helper'
require 'file_format_config'

module FixedWidthFileValidator
  class Record
    attr_accessor :_meta_

    def initialize
      @_meta_ = 1
    end

    def method_missing(m, *_args)
      puts "There's no method called #{m} here -- please try again."
    end
  end

  class RecordParser
    attr_reader :field_list, :encoding

    def initialize(field_list, encoding)
      @field_list = field_list
      @encoding = encoding || 'ISO-8859-1'
    end

    def parse(line)
      record = {}
      encoded = line.encode(@encoding, 'binary', invalid: :replace, undef: :replace)
      field_list.each do |field|
        record[field[:name].to_sym] = encoded[field[:position]].nil? ? nil : encoded[field[:position]].strip
      end
      record
    end
  end

  class FieldValidationError
    def initialize(validation, record, _field_name)
      @x = 1
      error_field_value = record[error_field_name]
      {
        record: record,
        error_field_name: error_field_name,
        error_field_value: error_field_value,
        validation: validation,
        error: error,
        row_number: current_row,
        source_line: line
      }
    end
  end

  class FieldValidator
    attr_accessor :record_type, :field_name, :non_unique_values, :validations

    @field_validators = {}

    # not threadsafe
    def self.for(record_type, field_name)
      @field_validators[:field_name] ||= FieldValidator.new(record_type, field_name)
    end

    def initialize(record_type, field_name)
      self.record_type = record_type
      self.field_name = field_name
      self.non_unique_values = []
      self.validations = FileFormat.for(record_type).field_validations(field_name)
    end

    # return an array of error objects
    # nil if all validation passes
    def validate(record, field_name)
      if validations
        validations.select do |validation|
          FieldValidationError.new(validation, record, field_name) unless valid_value?(validation, record, field_name)
        end
      elsif record && record[field_name]
        # when no validation rules exist for the field, just check if the field exists in the record
        nil
      else
        raise "found field value nil in #{record} field #{field_name}, shouldn't be possible?"
      end
    end

    def valid_value?(validation, record, field_name)
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
    attr_reader :record_type

    # # not threadsafe
    # def self.for(record_type)
    #   @@record_validators ||=  {}
    #   @@record_validators[record_type] ||=  RecordValidator.new(record_type)
    # end

    def validate(record)
      errors = []
      record.each_key do |field_name|
        result = FieldValidator.for(record_type, field_name).validate(record, field_name)
        errors << result if result
      end
      errors.flatten
    end
  end

  # def vali2date(data_file)
  #   @data_file_path = data_file
  #   @non_unique_values = find_non_unique_values
  #
  #   errors = []
  #
  #   each_line_in_data_file do |line|
  #     record = parser.parse_line(line)
  #     record.each_key do |field_name|
  #       rule.field_validations(field_name).each do |validation|
  #         begin
  #           result = validator(field_name, validation, record)
  #           errors << validation_error(line, record, field_name, validation, 'failed') unless result
  #         rescue StandardError => e
  #           errors << validation_error(line, record, field_name, validation, e)
  #         end
  #       end
  #     end
  #   end
  #
  #   # filter out the error from bottom lines we should ignore
  #   # at this point current_row should be at last row + 1
  #   errors.select {|err| err[:row_number] < @current_row - @skip_bottom_lines}
  # end

  private

  # def find_non_unique_values
  #   return if rule.unique_fields.empty?
  #
  #   lookup_hash = build_unique_value_lookup_hash
  #
  #   result = {}
  #   rule.unique_fields.each do |field_name|
  #     result[field_name] = lookup_hash[field_name].select {|_k, v| v.count > 1}
  #   end
  #   result
  # end
  #
  # def build_unique_value_lookup_hash
  #   tmp_store = {}
  #
  #   each_line_in_data_file do |line|
  #     record = parser.parse_line(line)
  #     rule.unique_fields.each do |field_name|
  #       tmp_store[field_name] ||= {}
  #       tmp_store[field_name][record[field_name]] ||= []
  #       tmp_store[field_name][record[field_name]] << current_row
  #     end
  #   end
  #
  #   tmp_store
  # end

  def each_line_in_data_file
    file = File.open(@data_file_path)
    @current_row = 1

    until file.eof?
      line = file.readline

      if @current_row <= @skip_top_lines || line.chomp.strip.empty?
        @current_row += 1
        next
      end

      # puts "#{Time.now} - #{@current_row}" if @current_row % 1000 == 0

      yield line

      @current_row += 1
    end
  ensure
    file.close
  end
end
