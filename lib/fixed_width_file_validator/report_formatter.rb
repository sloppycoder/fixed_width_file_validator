require 'fixed_width_file_validator/validator'

module FixedWidthFileValidator
  class TextReportFormatter
    attr_accessor :line_no_width

    def initialize(args = {})
      @line_no_width = args[:line_no_width] || 5
    end

    def write(err, file = $stderr)
      return if err.nil?

      line_prefix = format("%0#{line_no_width}i:", err.line_num)
      marker = line_prefix + ' ' * (err.pos - 1) + '^' * err.width
      message = line_prefix + ' ' * (err.pos - 1) + "field #{err.failed_field} does not satisfy #{err.failed_validation}"
      file.puts line_prefix + err.raw.chop
      file.puts marker
      file.puts message
      file.puts
    end

    def write_unique_errors(errors, file = $stderr)
      return if errors.empty?

      err = errors.first
      pos = err.pos - 1
      width = err.width
      line_prefix = format("%0#{line_no_width}i:", err.line_num)

      errors.each { |e| file.puts line_prefix + e.raw.chop }
      file.puts line_prefix + ' ' * pos + '^' * width
      file.puts line_prefix + ' ' * pos + "field #{err.failed_field} is not #{err.failed_validation}"
    end
  end
end
