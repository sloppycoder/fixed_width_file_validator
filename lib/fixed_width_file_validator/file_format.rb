require 'fixed_width_file_validator/file_reader'
require 'fixed_width_file_validator/validator'
require 'fixed_width_file_validator/record_parser'
require 'fixed_width_file_validator/record_formatter'

require 'yaml'

module FixedWidthFileValidator
  class FileFormat
    attr_reader :record_type, :fields, :unique_fields, :file_settings

    @all_formats = {}

    # not threadsafe
    def self.for(record_type, config_file = nil)
      @all_formats[record_type.to_sym] ||= FileFormat.new(record_type.to_sym, config_file)
    end

    def initialize(record_type, config_file = nil)
      @record_type = record_type.to_sym
      @fields = {}
      @unique_fields = []
      @parser_field_list = []
      @formatter_field_list = []
      @file_settings = {}
      @column = 1
      @config_file = config_file

      File.open(@config_file) do |f|
        @raw_config = symbolize(YAML.safe_load(f, [], [], true))
      end

      load_config(@record_type)
      find_unique_fields
    end

    def field_validations(field_name)
      fields[field_name]&.fetch :validations
    end

    def create_file_reader(data_file_path)
      FixedWidthFileValidator::FileReader.new(data_file_path, record_parser, file_settings)
    end

    def create_record_validator
      FixedWidthFileValidator::RecordValidator.new fields
    end

    def create_record_validator_with_reader(data_file_path)
      # in this scenario the reader will read through the file to find unique values
      # so we need to create a new reader and close it when done
      reader = create_file_reader(data_file_path)
      FixedWidthFileValidator::RecordValidator.new fields, unique_fields, reader
    ensure
      reader.close
    end

    def record_formatter
      @record_formatter ||= RecordFormatter.new(@formatter_field_list, file_settings[:encoding])
    end

    def record_parser
      @record_parser ||= RecordParser.new(@parser_field_list, file_settings[:encoding])
    end

    private

    def load_config(record_type)
      format_config = config_for(record_type)
      format_config[:fields].each do |field_config|
        field_config = parse_field_config(field_config)
        key = field_config[:field_name].to_sym
        @fields[key] = field_config
        @parser_field_list << parser_params(key)
        @formatter_field_list << formatter_params(key)
        @column = fields[key][:end_column] + 1
      end
      @file_settings = { skip_top_lines: format_config[:skip_top_lines] || 0,
                         skip_bottom_lines: format_config[:skip_bottom_lines] || 0 }
    end

    def parse_field_config(field_config)
      width = field_config[:width]
      return unless width&.positive?

      field_name = field_config[:name] || "field_#{@column}"
      start_column = field_config[:starts_at] || @column
      end_column = start_column + width - 1
      validations = field_config[:validate]
      validations = [validations] unless validations.is_a?(Array)
      format = field_config[:format] || "%-#{width}s" # defaults to left aligned text

      {
        field_name: field_name,
        start_column: start_column,
        end_column: end_column,
        validations: validations,
        output_format: format
      }
    end

    def find_unique_fields
      fields.each do |field_name, field_rule|
        next if field_rule[:validations].select { |v| v == 'unique' }.empty?
        unique_fields << field_name
      end
    end

    def parser_params(field_name)
      f = fields[field_name]
      # in config file column starts with 1 but when parsing line begins at 0
      { name: field_name, position: (f[:start_column] - 1..f[:end_column] - 1) }
    end

    def formatter_params(field_name)
      f = fields[field_name]
      { name: field_name, position: f[:start_column], width: f[:end_column] - f[:start_column] + 1, format: f[:output_format] }
    end

    def config_for(record_type)
      format_config = @raw_config[record_type]
      format_fields = format_config[:fields]
      inherit_format = format_config[:inherit_from]&.to_sym

      if inherit_format
        inherit_config = @raw_config[inherit_format]
        inherit_fields = inherit_config ? inherit_config[:fields] : []

        inherit_fields.each do |field|
          format_fields << field if format_fields.select { |f| f[:name] == field[:name] }.empty?
        end
      end

      format_config
    end

    def symbolize(obj)
      return obj.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = symbolize(v); } if obj.is_a? Hash
      return obj.each_with_object([]) { |v, memo| memo << symbolize(v); } if obj.is_a? Array
      obj
    end
  end
end
