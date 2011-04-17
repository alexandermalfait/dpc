require 'jars/poi-3.5-FINAL-20090928.jar'
include Java

include_class java.io.FileInputStream
include_class Java::org.apache.poi.hssf.usermodel.HSSFWorkbook
include_class Java::org.apache.poi.hssf.usermodel.HSSFSheet
include_class Java::org.apache.poi.hssf.usermodel.HSSFRow
include_class Java::org.apache.poi.hssf.usermodel.HSSFCell

class ExcelWorkBook

  def initialize(xlsFile)
    input = FileInputStream.new(xlsFile)
    @hssfworkbook = HSSFWorkbook.new(input)
  end

  def worksheet(sheet_position)
    ExcelWorkSheet.new(@hssfworkbook.getSheetAt(sheet_position), sheet_position)
  end

  class ExcelWorkSheet

    def initialize(hssfworksheet, sheet_position)
      @index = sheet_position
      @hssfworksheet = hssfworksheet
    end

    def row_at(rownumber)
      return Row.new(@hssfworksheet.getRow(rownumber))
    end

    def rows
      rows = []
      for row in @hssfworksheet.rowIterator
        rows << Row.new(row)
      end
      rows
    end

    def list_by_header
      list = []

      rows = self.rows

      headers = rows.shift

      rows.each do |row|
        values = {}

        headers.each_with_index do |header, index|
          values[header] = row.value_at(index)
        end

        list << values
      end

      list
    end

    class Row

      include Enumerable

      def initialize(hssfrow)
        @hssfrow = hssfrow
      end

      def each
        index = 0

        while(true)
          value = value_at(index)

          if value == nil
            break
          end

          yield value

          index += 1
        end
      end

      def value_at(columnindex)
        cell = @hssfrow.cell(columnindex)

        if (cell == nil)
          nil
        elsif (HSSFCell::CELL_TYPE_NUMERIC == cell.getCellType())
          cell.numeric_cell_value

        elsif (HSSFCell::CELL_TYPE_STRING == cell.getCellType())
          cell.string_cell_value
        end

      end

    end

  end
end