require 'spreadsheet'
# require 'plutolib/clean_evil_characters'

module Plutolib::ToXls
  class Field
    # include Plutolib::CleanEvilCharacters
    attr_reader :column_header, :format
    def initialize(column_header, format=nil, &value_block)
      @format = format
      @column_header = column_header
      @value_block = value_block
    end
    def value_for(data_object)
      value = @value_block.call(data_object)
      if value.is_a?(BigDecimal)
        value = value.to_f.round(2)
      # elsif value.is_a?(String)
      #   value = clean_evil_characters(value)
      end
      value
    end
  end
  
  def xls_initialize
    # Implement me!!!
  end
  
  def xls_fields
    if @xls_fields.nil?
      @xls_fields = []
      self.xls_initialize
    end
    @xls_fields
  end
  
  def xls_field(column_header, format=nil, &value_block)
    self.xls_fields.push Plutolib::ToXls::Field.new(column_header, format, &value_block)
  end

  def xls_each_sheet(&block)
    data = if self.respond_to?(:xls_data)
      self.xls_data
    else
      # Backwards compatibility
      self.all_data
    end
    yield(nil, self.xls_fields, data)
  end
  
  def to_xls(export_file=nil)
    book = Spreadsheet::Workbook.new
    self.xls_each_sheet do |sheet_name, sheet_fields, sheet_data|
      sheet = book.create_worksheet
      sheet.name = sheet_name if sheet_name
      column_formats = xls_column_formats(sheet_fields, sheet)
      row_number = 1
      sheet_data.each do |data_object|
        sheet_row = sheet.row(sheet.last_row_index+1)
        row_data = sheet_fields.map { |field| 
          field.value_for(data_object) 
        }
        sheet_row.push *row_data
        # Set formats for each cell in the row.
        for x in 0..row_data.size-1
          # sheet[row_number, x] = row_data[x]
          sheet_row.set_format(x, column_formats[x])
        end
        row_number += 1
      end
    end
    if export_file
      book.write export_file
    else
      s = StringIO.new
      book.write(s)
      s.string
    end
  end
    
  def xls_filename
    self.class.name.demodulize.underscore + '.xls'
  end
  
  def xls_sheet_name
    self.class.name.demodulize.humanize
  end
  
  def xls_time_format
    @xls_time_format ||= Spreadsheet::Format.new(:number_format => 'h:mm:ss AM/PM')
  end
  
  def xls_text_format
    @xls_text_format ||= Spreadsheet::Format.new
  end
  
  def xls_date_format
    @xls_date_format ||= Spreadsheet::Format.new(:number_format => 'mm/dd/yyyy')
  end
  
  def xls_header_format
    @xls_header_format ||= Spreadsheet::Format.new :weight => :bold, :size => 12
  end  

  def xls_no_decimals_format
    @no_decimals_number_format ||= Spreadsheet::Format.new(:number_format => '#,##0')
  end  

  protected

    def xls_column_formats(fields, sheet)
      default_column_formats = {}
      for x in 0..fields.size-1
        field = fields[x]
        sheet.row(0).push field.column_header
        sheet.row(0).set_format(x, self.xls_header_format)
        if field.format.present?
          default_column_formats[x] = field.format
        else
          case field.column_header
          when /Time/
            sheet.column(x).width = 11
            default_column_formats[x] = self.xls_time_format
          when /Date/
            sheet.column(x).width = 11
            default_column_formats[x] = self.xls_date_format
          else
            default_column_formats[x] = self.xls_text_format
          end
        end
      end
      default_column_formats
    end
end
