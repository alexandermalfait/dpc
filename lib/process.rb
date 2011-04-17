# configuration

FOLDER = 'C:\Users\Alex\Desktop\DPC\reran'

SOURCE_LANGUAGES = {'NL' => 'NL_orig', 'EN' => 'NL<EN', 'FR' => 'NL<FR' }

KEEP_LANGUAGE = 'NL-BE'

TEXT_TYPES = {
  'External Communication' => 'Extern',
  'Administrative texts' => 'Admin',
  'Instructive texts' => 'Instr',
  'Journalistic texts' => 'Journal',
  'Fictional literature' => 'Fictie',
  'Non-fictional literature' => 'Non_Fic'
}

# code

require "excel_work_book"
require "poi_excel_writer"
require "date"

Dir.chdir(FOLDER)

data = []

Dir["*.xls"].each do |source_file|
  puts "Processing #{source_file}"

  workbook = ExcelWorkBook.new(File.expand_path(source_file))

  workbook.worksheet(0).list_by_header.each do |row|
    raise "Relevantie ontbreekt in #{source_file}" unless row['Relevantie'] && row['Relevantie'] != ""

    next unless row['Taal'] == KEEP_LANGUAGE

    next unless row['Relevantie'] == 'r'

    next unless SOURCE_LANGUAGES[row['Brontaal']]

    row['Brontaal'] = SOURCE_LANGUAGES[row['Brontaal']]

    row['Text Type'] = TEXT_TYPES[row['Text Type']]

    data << row
  end
end

puts "Sorting data"

data = data.sort_by { |row| row['Benaming']}

puts "Writing result"

result_excel = PoiExcelWriter.new

result_excel.create_sheet "Resultaten"
result_excel.write_list_of_hashes(data)

File.open("result.xls", "wb") do |result_file|
  result_file.write result_excel.excel_content
end

puts "Saved result to #{File.expand_path("result.xls")}"


