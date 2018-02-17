require 'fixed_width_file_validator/version'
require 'erb'
require 'yaml'

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

  class Rule
    attr_reader :parser_field_list, :unique_fields, :rules

    def initialize(rule_file, file_format, bindings = binding)
      @column = 0
      @config = ERB.new(rule_file).result(bindings)
      @rules = {}
      @parser_field_list = []
      @unique_fields = []

      parse_rules file_format
      find_unique_fields
    end

    def field_validations(field_name)
      rules[field_name][:validations]
    end

    private

    def parse_rules(file_format)
      config_for_format(file_format)[:fields].each do |field_config|
        field_rule = parse_field_rules(field_config)
        key = field_rule[:field_name].to_sym
        rules[key] = field_rule
        parser_field_list << parser_params(key)
        @column = rules[key][:end_column] + 1
      end
    end

    def parse_field_rules(field_rule)
      width = field_rule[:width]
      return unless width && width > 0

      field_name = field_rule[:name] || "field_#{@column}"
      start_column = field_rule[:starts_at] || @column
      end_column = start_column + width - 1

      {
        field_name: field_name,
        start_column: start_column,
        end_column: end_column,
        validations: field_rule[:validate]
      }
    end

    def find_unique_fields
      rules.each do |field_name, field_rule|
        next if field_rule[:validations].select { |v| v == 'unique' }.empty?
        unique_fields << field_name
      end
    end

    def parser_params(field_name)
      f = rules[field_name]
      { name: field_name, position: (f[:start_column]..f[:end_column]) }
    end

    def config_for_format(file_format)
      symbolize(YAML.safe_load(@config, [], [], true))[file_format]
    end

    def symbolize(obj)
      return obj.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = symbolize(v);  } if obj.is_a? Hash
      return obj.each_with_object([]) { |v, memo| memo << symbolize(v); } if obj.is_a? Array
      obj
    end
  end

  class Parser
    attr_reader :field_list

    def initialize(field_list)
      @field_list = field_list
    end

    def parse_line(line)
      record = {}
      field_list.each do |field|
        record[field[:name].to_sym] = line[field[:position]].nil? ? nil : line[field[:position]].strip
      end
      record
    end
  end

  class Validator
    attr_reader :parser, :rule, :non_unique_values, :current_row

    def initialize(rule_file, file_format)
      @rule = Rule.new(File.read(rule_file), file_format)
      @parser = Parser.new(rule.parser_field_list)
      @current_row = 0
    end

    def validate(data_file)
      @data_file_path = data_file
      @non_unique_values = find_non_unique_values

      errors = []

      each_line_in_data_file do |line|
        record = parser.parse_line(line)
        record.each_key do |field_name|
          rule.field_validations(field_name).each do |validation|
            begin
              result = validator(field_name, validation, record)
              errors <<  validation_error(line, record, field_name, validation, 'failed') unless result
            rescue StandardError => e
              errors <<  validation_error(line, record, field_name, validation, e)
            end
          end
        end
      end

      errors
    end

    private

    def validator(field_name, validator, record)
      value = record[field_name]
      return false if value.nil?

      value.extend(StringHelper)
      if validator == 'unique'
        !non_unique_values[field_name].include?(value)
      elsif value.respond_to?(validator)
        value.public_send(validator)
      else
        code = "lambda { |r| #{validator} }"
        value.instance_eval(code).call(record)
      end
    end

    def find_non_unique_values
      return if rule.unique_fields.empty?

      lookup_hash = build_unique_value_lookup_hash

      result = {}
      rule.unique_fields.each do |field_name|
        result[field_name] = lookup_hash[field_name].select { |_k, v| v.count > 1 }
      end
      result
    end

    def build_unique_value_lookup_hash
      tmp_store = {}

      each_line_in_data_file do |line|
        record = parser.parse_line(line)
        rule.unique_fields.each do |field_name|
          tmp_store[field_name] ||= {}
          tmp_store[field_name][record[field_name]] ||= []
          tmp_store[field_name][record[field_name]] << current_row
        end
      end

      tmp_store
    end

    def each_line_in_data_file
      file = File.open(@data_file_path)
      current_row = 1

      until file.eof?
        line = file.readline
        if line.chomp.strip.empty?
          current_row += 1
          next
        end

        yield line

        current_row += 1
      end
    ensure
      file.close
    end

    def validation_error(line, record, error_field_name, validation, error)
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
end
