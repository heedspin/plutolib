require 'spreadsheet'
require 'plutolib/csv_to_hash'

module Plutolib
  class XlsToHash
    def self.parse_file(path, &block)
      book = Spreadsheet.open(path)
      book.worksheets.each do |sheet|
        self.parse_worksheet(sheet, &block)
      end
    end
    
    def self.parse_worksheet(sheet,&block)
      header = sheet.row(0)
      sheet.each(1) do |row|
        row_hash = {}
        row.each_with_index do |value, index|
          value = CsvToHash.clean_value(value)
          row_hash[header[index]] = value unless value.nil?
        end
        yield(row_hash)
      end
    end
  end
end