require_relative 'test_helper'

class FileFormatConfigurationTest < Minitest::Test
  def test_can_parse_sample_file
    sample_config = %{
common_fields:
  fields:
    - name: name
      width: 20
      starts_at: 1
      validate:
        - not_blank
        - "^ include?('LIN') ? left_justified : right_justified"

test_format_1:
  skip_top_lines: 1
  skip_bottom_lines: 1
  inherit_from: common_fields
  new_line_style: true
  fields:
    - name: phone
      width: 12
      starts_at: 21
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
}

    with_tmp_file_from_string(sample_config) do |config_file_path|
      format = FixedWidthFileValidator::FileFormat.for(:test_format_1, config_file_path)

      total_fields = 5
      assert format.fields.size == total_fields # inherit_from works
      assert format.record_parser.field_list.size == total_fields
      assert format.field_validations(:phone).include? 'unique'
      assert format.field_validations(:field_86).is_a? Array
      assert format.field_validations(:field_83).is_a? Array
      assert format.field_validations(:field_83).first == 'XYZ'
      assert format.field_validations(:non_existent).nil?
    end
  end
end
