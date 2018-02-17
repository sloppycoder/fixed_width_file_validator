require 'fixed_width_file_validator/version'
require 'fixed_width_file_parser'
require 'erb'
require 'yaml'
require 'logger'

module FixedWidthFileValidator
  module StringHelper
    def any
      true
    end

    def text
      is_a? String
    end

    def blank
      strip.empty?
    end

    def not_blank
      !blank
    end

    def width(w)
      size == w
    end

    def numeric(precision = 0)
      m = /^(\d*)\.?(\d*)$/.match(self)
      m && m[1] && m[2].size == precision
    end

    def left_justified
      index(strip).zero?
    end

    def right_justified
      rindex(strip) == (length - strip.length)
    end
  end

  class RuleReader
    attr_reader :config, :rules

    def initialize(rule_file, bindings = binding)
      @config = ERB.new(rule_file).result(bindings)
      @rules = symbolize(YAML.safe_load(@config, [], [], true))
    end

    private

    def symbolize(obj)
      return obj.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = symbolize(v);  } if obj.is_a? Hash
      return obj.each_with_object([]) { |v, memo| memo << symbolize(v); } if obj.is_a? Array
      obj
    end
  end

  class Validator
    attr_reader :fields, :validators, :non_unique_values
    attr_writer :logger

    def initialize(rule_file, file_type)
      @fields = []
      @validators = {}
      column = 0

      rules = RuleReader.new(File.read(rule_file)).rules
      rules[file_type][:fields].each do |field|
        width = field[:width]
        unless width && width > 0
          logger.warn "field #{field} skipped, width is not specified"
          next
        end

        field_name = field[:name] || "field_#{column}"
        start_column = field[:starts_at] || column
        end_column = start_column + width - 1

        fields << { name: field_name, position: (start_column..end_column) }
        validators[field_name.to_sym] = field[:validate] || []

        column = end_column + 1
      end
    end

    def find_non_unique_values(data_file)
      unique_fields = find_unique_fields
      return if unique_fields.empty?

      row_number = 1
      tmp_store = {}
      FixedWidthFileParser.parse(data_file, fields) do |record_hash|
        unique_fields.each do |field_name|
          tmp_store[field_name] ||= {}
          tmp_store[field_name][record_hash[field_name]] ||= []
          tmp_store[field_name][record_hash[field_name]] << row_number
        end
        row_number += 1
      end

      result = {}
      unique_fields.each do |field_name|
        result[field_name] = tmp_store[field_name].select { |_k, v| v.count > 1 }
      end

      result
    end

    def find_unique_fields
      unique_fields = []
      validators.each_key do |field_name|
        unique_fields << field_name unless validators[field_name].select { |v| v == 'unique' }.empty?
      end
      unique_fields
    end

    def validate(data_file)
      @non_unique_values = find_non_unique_values(data_file)

      errors = []

      row_number = 1
      FixedWidthFileParser.parse(data_file, fields) do |record_hash|
        next if record_hash.empty? || strip_values(record_hash).empty?

        record_hash.each_key do |field_name|
          validators[field_name].each do |validator|
            begin
              result = eval_validator(field_name, validator, record_hash)
              errors <<  validation_error(record_hash, field_name, validator, row_number, 'failed') unless result
            rescue StandardError => e
              errors <<  validation_error(record_hash, field_name, validator, row_number, e)
            end
          end
        end
        row_number += 1
      end

      errors
    end

    def logger
      return @logger if @logger
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @logger
    end

    private

    def strip_values(hash)
      hash.select { |_k, v| v && !v.strip.empty? }
    end

    def eval_validator(field_name, validator, record)
      value = record[field_name]
      return false if value.nil?

      value.extend(StringHelper)
      if validator == 'unique'
        !@non_unique_values[field_name].include?(value)
      elsif value.respond_to?(validator)
        value.public_send(validator)
      else
        code = "lambda { |r| #{validator} }"
        value.instance_eval(code).call(record)
      end
    end

    def validation_error(record, error_field_name, validator, row_number, error)
      error_field_value = record[error_field_name]
      {
        record: record,
        error_field_name: error_field_name,
        error_field_value: error_field_value,
        validator: validator,
        error: error,
        row_number: row_number
      }
    end
  end
end
