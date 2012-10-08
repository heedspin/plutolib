require 'spreadsheet'

module Plutolib::ToXls
  class Field
    attr_reader :column_header, :number_format
    def initialize(column_header, number_format=nil, &value_block)
      @number_format = number_format
      @column_header = column_header
      @value_block = value_block
    end
    def value_for(data_object)
      @value_block.call(data_object)
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
  
  def xls_field(column_header, number_format=nil, &value_block)
    self.xls_fields.push Plutolib::ToXls::Field.new(column_header, number_format, &value_block)
  end
  
  def to_xls
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet
    sheet.name = self.xls_sheet_name
    column_formats = xls_column_formats(self.xls_fields, sheet)
    self.all_data.each do |data_object|
      sheet_row = sheet.row(sheet.last_row_index+1)
      row_data = self.xls_fields.map { |field| 
        field.value_for(data_object) 
      }
      sheet_row.push *row_data
      # Set formats for each cell in the row.
      for x in 0..row_data.size-1
        sheet_row.set_format(x, column_formats[x])
      end
    end

    s = StringIO.new
    book.write(s)
    s.string
  end
  
  def xls_filename
    self.class.name.demodulize.underscore
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

  protected

    def xls_column_formats(fields, sheet)
      default_column_formats = {}
      for x in 0..fields.size-1
        field = fields[x]
        sheet.row(0).push field.column_header
        sheet.row(0).set_format(x, self.xls_header_format)
        if field.number_format.present?
          default_column_formats[x] = field.number_format
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

    # DEC to OCT to HEX Mapping:
    # 128.chr => \200 => \x80
    # 153.chr => \231 => \x99
    # 156.chr => \234 => \x9c
    # 157.chr => \235 => \x9d
    # 162.chr => \242 => \xA2
    # 194.chr => \302 => \xC2
    # 195.chr => \303 => \xC3  ==> bang
    # 226.chr => \342 => \xE2
    EVIL_CHARACTERS = [153, 160, 162, 194, 195, 226]
    def xls_clean(txt)
      return txt unless txt.is_a?(String)

      # Evil curly quote replace
      txt = txt.gsub("\xE2\x80\x9c", '"')
      txt = txt.gsub("\xE2\x80\x9d", '"')

      # Get rid of evil A characters:
      # <"Miguel&#39;s"> expected but was
      # <"MiguelÂ&#39;s">.
      EVIL_CHARACTERS.each { |evilc| txt = txt.delete evilc.chr }

      # Replace evil quotes with regular quotes.
      txt = txt.tr "\x91-\x94\x9c\x9d\x80", "''\"\"\"\"'"

      # Entity encode quotes.
      # txt = txt.gsub("'", '&#39;')
      # txt = txt.gsub('"', '&#34;')
      txt.strip
    end
end
