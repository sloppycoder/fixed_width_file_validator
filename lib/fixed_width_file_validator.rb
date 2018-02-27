require 'fixed_width_file_validator/version'
require 'yaml'
require 'date'
require 'time'
require 'ripper'

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

    def date_time(format = '%Y%m%d%H%M%S')
      Time.strptime(self, format)
      length == 14
    rescue ArgumentError
      false
    end

    def date(format = '%Y%m%d')
      Date.strptime(self, format)
      length == 8
    rescue ArgumentError
      false
    end

    def time
      return false unless length == 6
      h = self[0..1].to_i
      m = self[2..3].to_i
      s = self[4..5].to_i
      h >= 0 && h < 24 && m >= 0 && m < 60 && s >= 0 && s < 60
    end

    def time_or_blank
      blank || time
    end

    def date_or_blank(format = '%Y%m%d')
      blank || date(format)
    end

    def positive
      to_i.positive?
    end

    def numeric(max = 32, precision = 0, min = 1)
      m = /^(\d*)\.?(\d*)$/.match(self)
      m && m[1] && (min..max).cover?(m[1].size) && m[2].size == precision
    end

    def numeric_or_blank(max = 32, precision = 0, min = 1)
      blank || numeric(max, precision, min)
    end

    def left_justified
      index(strip).zero?
    end

    def right_justified
      rindex(strip) == (length - strip.length)
    end
  end

  class Rule
    attr_reader :parser_field_list, :unique_fields, :rules, :file_settings

    def initialize(rule_file, file_format)
      @column = 0
      @rules = {}
      @parser_field_list = []
      @unique_fields = []
      @config = rule_file
      @file_settings = {}

      parse_rules file_format
      find_unique_fields
    end

    def field_validations(field_name)
      rules[field_name][:validations]
    end

    private

    def parse_rules(file_format)
      format_config = config_for_format(file_format)
      format_config[:fields].each do |field_config|
        field_rule = parse_field_rules(field_config)
        key = field_rule[:field_name].to_sym
        rules[key] = field_rule
        parser_field_list << parser_params(key)
        @column = rules[key][:end_column] + 1
      end
      @file_settings = { skip_top_lines: format_config[:skip_top_lines] || 0,
                         skip_bottom_lines: format_config[:skip_bottom_lines] || 0 }
    end

    def parse_field_rules(field_rule)
      width = field_rule[:width]
      return unless width&.positive?

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
      # in config file column starts with 1 but when parsing line begins at 0
      { name: field_name, position: (f[:start_column] - 1..f[:end_column] - 1) }
    end

    def config_for_format(file_format)
      all_configs = symbolize(YAML.safe_load(@config, [], [], true))
      format_config = all_configs[file_format.to_sym]
      format_fields = format_config[:fields]
      inherit_format = format_config[:inherit_from]

      if inherit_format
        inherit_config = all_configs[inherit_format.to_sym]
        inheirt_fields = inherit_config ? inherit_config[:fields] : []

        inheirt_fields.each do |field|
          format_fields << field if format_fields.select { |f| f[:name] == field[:name] }.empty?
        end
      end

      format_config
    end

    def symbolize(obj)
      return obj.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = symbolize(v);  } if obj.is_a? Hash
      return obj.each_with_object([]) { |v, memo| memo << symbolize(v); } if obj.is_a? Array
      obj
    end
  end

  class Parser
    attr_reader :field_list, :encoding

    def initialize(field_list, encoding)
      @field_list = field_list
      @encoding = encoding
    end

    def parse_line(line)
      record = {}
      utf8_line = line.encode('UTF-8', 'binary', invalid: :replace, undef: :replace)
      field_list.each do |field|
        record[field[:name].to_sym] = utf8_line[field[:position]].nil? ? nil : utf8_line[field[:position]].strip
      end
      record
    end
  end

  class Validator
    attr_reader :parser, :rule, :non_unique_values, :current_row

    def initialize(rule_file, file_format)
      @rule = Rule.new(File.read(rule_file), file_format)
      encoding = @rule.file_settings[:encoding] || 'ISO-8859-1'
      @parser = Parser.new(rule.parser_field_list, encoding)
      @current_row = 0
      @skip_top_lines = @rule.file_settings[:skip_top_lines]
      @skip_bottom_lines = @rule.file_settings[:skip_bottom_lines]
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

      # filter out the error from bottom lines we should ignore
      # at this point current_row should be at last row + 1
      errors.select { |err| err[:row_number] < @current_row - @skip_bottom_lines }
    end

    private

    def validator(field_name, validator, record)
      value = record[field_name]
      return false if value.nil?

      value.extend(StringHelper)

      if validator.is_a? String
        keyword = Ripper.tokenize(validator).first

        if validator == 'unique'
          !non_unique_values[field_name].include?(value)
        elsif keyword == '^' ||  value.respond_to?(keyword)
          validator = validator[1..500] if keyword == '^'
          code = "lambda { |r| #{validator} }"
          value.instance_eval(code).call(record)
        else
          value == validator
        end
      elsif validator.is_a? Array
        validator.include? value
      else
        false
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
      @current_row = 1

      until file.eof?
        line = file.readline

        if @current_row <= @skip_top_lines || line.chomp.strip.empty?
          @current_row += 1
          next
        end

        puts "#{Time.now} - #{@current_row}" if @current_row % 1000 == 0

        yield line

        @current_row += 1
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

class String
  include FixedWidthFileValidator::StringHelper
end
