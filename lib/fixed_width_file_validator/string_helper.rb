require 'date'
require 'time'

module FixedWidthFileValidator
  module StringHelper
    def any
      true
    end

    def blank
      strip.empty?
    end

    def not_blank
      !blank
    end

    def width(num)
      size == num
    end

    def date_time(format = '%Y%m%d%H%M%S')
      Time.strptime(self, format)
    rescue ArgumentError
      false
    end

    def date(format = '%Y%m%d')
      # since exception is slow, optimize for known format here
      if format == '%Y%m%d'
        return false unless length == 8
        y = slice(0..3).to_i
        m = slice(4..5).to_i
        d = slice(6..7).to_i
        Date.valid_date?(y, m, d)
      else
        Date.strptime(self, format)
      end
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
  end
end

class String
  include FixedWidthFileValidator::StringHelper
end
