require 'java'
require 'jars/poi-3.5-FINAL-20090928.jar'
include_class 'org.apache.poi.poifs.filesystem.POIFSFileSystem'
include_class 'org.apache.poi.hssf.usermodel.HSSFCell'
include_class 'org.apache.poi.hssf.usermodel.HSSFWorkbook'
include_class 'org.apache.poi.hssf.usermodel.HSSFCellStyle'
include_class 'org.apache.poi.hssf.usermodel.HSSFDataFormat'
include_class 'java.io.ByteArrayOutputStream'
include_class 'org.apache.poi.hssf.usermodel.HSSFFont'

class PoiExcelWriter

  def initialize
    @book = HSSFWorkbook.new

    create_styles
  end

  def create_sheet(name)
    @book.create_sheet(name)

    select_sheet(name)
  end

  def select_sheet(name)
    @sheet = @book.get_sheet(name)

    @current_row = 0
  end

  def write_row(data, style = nil)
    raise "You need to create a worksheet first using create_sheet" unless @sheet

    if style && !@styles[style]
      raise "Unknown style '#{style}'"
    end

    row = @sheet.create_row(@current_row)

    data.each_with_index do |value, index|
      if value
        cell = row.create_cell(index)

        write_value_to_cell(cell, value)

        cell.cell_style = @styles[style] if style
      end 
    end

    @current_row += 1
  end

  def skip_row
    @current_row += 1
  end

  def write_list_of_hashes(data, options = {})
    if options[:headers]
      write_row options[:headers], :bold
    else
      write_row data.first.keys, :bold
    end

    data.each do |row|
      write_row row.values
    end
  end

  def excel_content
    stream = ByteArrayOutputStream.new
    @book.write(stream)
    stream.close

    return String.from_java_bytes(stream.to_byte_array)
  end

  def auto_size_columns
    1.upto(250) do |i|
      @sheet.auto_size_column(i)
    end
  end

  private

  def create_styles
    @styles = {}

    @styles[:date] = @book.create_cell_style
    @styles[:date].data_format = @book.create_data_format.get_format("dd/mm/yyyy")

    @styles[:date_time] = @book.create_cell_style
    @styles[:date_time].data_format = @book.create_data_format.get_format("dd/mm/yyyy h:mm")

    bold_font = @book.create_font
    bold_font.boldweight = HSSFFont::BOLDWEIGHT_BOLD
    @styles[:bold] = @book.create_cell_style
    @styles[:bold].font = bold_font
  end

  def write_value_to_cell(cell, value)
    case value
      when Date
        cell.set_cell_value(java.util.Date.new(value.to_datetime.to_f * 1000))
        cell.set_cell_style(@styles[:date])

      when DateTime, Time
        cell.set_cell_value(java.util.Date.new(value.to_datetime.to_f * 1000))
        cell.set_cell_style(@styles[:date_time])

      when Numeric
        cell.set_cell_value(java.lang.Double.parse_double(value.to_s))

      else
        cell.set_cell_value(value.to_s)
    end
  end
end