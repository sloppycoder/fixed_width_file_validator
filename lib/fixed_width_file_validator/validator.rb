require 'ripper'

module FixedWidthFileValidator
  class FieldValidationError
    attr_reader :raw, :record, :line_num, :failed_field, :failed_value, :failed_validation, :pos, :width

    def initialize(validation, record, field_name, pos, width)
      @raw = record[:_raw]
      @line_num = record[:_line_num]
      @record = record
      @failed_field = field_name
      @failed_validation = validation
      @failed_value = record[field_name]
      @pos = pos
      @width = width
    end
  end

  # rubocop:disable Style/ClassVars
  class FieldValidator
    attr_accessor :field_name, :non_unique_values, :validations, :pos, :width

    @@token_cache = {}

    def initialize(field_name, pos, width, validations = nil)
      self.field_name = field_name
      self.non_unique_values = []
      self.validations = validations
      self.pos = pos
      self.width = width
    end

    # return an array of error objects
    # empty array if all validation passes
    def validate(record, field_name, bindings = {})
      if validations
        validations.collect do |validation|
          unless valid_value?(validation, record, field_name, bindings)
            FieldValidationError.new(validation, record, field_name, pos, width)
          end
        end.compact
      elsif record && record[field_name]
        # when no validation rules exist for the field, just check if the field exists in the record
        []
      else
        raise "found field value nil in #{record} field #{field_name}, shouldn't be possible?"
      end
    end

    private

    def valid_value?(validation, record, field_name, bindings)
      value = record[field_name]
      if value.nil?
        false
      elsif validation.is_a? String
        keyword = keyword_for(validation)
        if validation == 'unique'
          !non_unique_values.include?(value)
        elsif validation == keyword && value.respond_to?(keyword)
          # this scenario can be handled by instance_eval too
          # we do this as an optimization since it is much faster
          value.public_send(validation)
        elsif keyword == '^' || value.respond_to?(keyword)
          validation = validation[1..-1] if keyword == '^'
          code = "lambda { |r, _g| #{validation} }"
          value.instance_eval(code).call(record, bindings)
        else
          value == validation
        end
      elsif validation.is_a? Array
        validation.include? value
      else
        raise "Unknown validation #{validation} for #{record_type}/#{field_name}"
      end
    end

    def keyword_for(validation)
      @@token_cache[validation] ||= Ripper.tokenize(validation).first
      @@token_cache[validation]
    end
  end
  # rubocop:enable Style/ClassVars

  class RecordValidator
    attr_accessor :bindings

    def initialize(fields, unique_field_list = nil, reader = nil)
      @field_validators = {}
      @bindings = {}

      non_unique_values = reader.find_non_unique_values(unique_field_list)

      fields.each do |field_name, conf|
        pos = conf[:start_column]
        width = conf[:end_column] - pos + 1
        @field_validators[field_name] = FieldValidator.new(field_name, pos, width, fields[field_name][:validations])
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
end
