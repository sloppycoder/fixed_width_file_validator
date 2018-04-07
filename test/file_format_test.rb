require_relative 'test_helper'

SAMPLE_CONFIG = %(
common_fields:
  fields:
    - name: name
      width: 20
      starts_at: 1
      validate:
        - not_blank

test_format_1:
  skip_top_lines: 1
  skip_bottom_lines: 1
  inherit_from: common_fields
  new_line_style: true
  fields:
    - name: phone
      width: 12
      starts_at: 21
      format: '%05d'
      validate:
        - start_with? '60'
        - unique
    - width: 50
      validate:
        - "^ include? r[:name]"
    - width: 3
      validate: 'XYZ'
    - width: 2
      validate:
        - width 2
        - ['AA', 'BB', 'CC']
).freeze

class FileFormatConfigurationTest < Minitest::Test
  def test_can_parse_sample_file
    with_tmp_file_from_string(SAMPLE_CONFIG) do |config_file_path|
      format = FixedWidthFileValidator::FileFormat.for(:test_format_1, config_file_path)


      total_fields = 5
      assert_equal total_fields, format.fields.size, 'inherit_from did not work'
      assert format.field_validations(:phone).include? 'unique'
      assert_instance_of Array, format.field_validations(:field_86)
      assert_instance_of Array, format.field_validations(:field_83)
      assert_equal 'XYZ', format.field_validations(:field_83).first
      assert_nil format.field_validations(:non_existent)

      record_formatter = format.record_formatter
      assert_equal '%05d', record_formatter.instance_variable_get('@field_list').at(1)[:format]
    end
  end
end
