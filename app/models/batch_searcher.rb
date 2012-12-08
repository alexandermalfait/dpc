include_class 'be.alex.dpc.Search'
include_class 'be.alex.dpc.SearchTerm'

class BatchSearcher

  def initialize(words, languages, output_folder)
    @words = words
    @languages = languages
    @output_folder = output_folder

    @statistics = {}
  end

  def execute
    @words.each_with_index do |word, index|
      puts "Processing #{index} / #{@words.size}"

=begin
      execute_search(
          "#{word}",
          { :word => word, :occurrence_type => "once"}
      )
=end

      execute_search(
          "#{word}",
          { :lemma => word, :occurrence_type => "once"}
      )
    end

    write_statistics
  end

  def write_statistics
    excel = PoiExcelWriter.new

    excel.create_sheet "Totalen"

    @statistics.each do |name, total|
      excel.write_row([ name, total ])
    end

    File.open("#@output_folder/_totals.xls", "wb") do |f|
      f.write(excel.excel_content)
    end
  end

  def execute_search(name, term)
    options = { :search_name => name }

    options[:term] = []

    options[:term] << { :occurrence_type => "wildcard", :index => 0 }
    term[:index] = 1
    options[:term] << term
    options[:term] << { :occurrence_type => "wildcard", :index => 2 }

    puts "Executing #{name}"

    search = SearchController.convert_params_to_search(options[:term], @languages)

    search_result = SEARCH_SERVICE.run_search(search)

    puts "Found #{search_result.size} results"

    @statistics[name] = search_result.size

    exporter = ExcelExporter.new(search_result.sentence_ids, options)

    File.open("#@output_folder/#{name}.xls", "wb") do |f|
      f.write(exporter.get_excel.excel_content)
    end
  end

  def wildcard
    wildcard = SearchTerm.new

    wildcard.min_occurrences = 0
    wildcard.max_occurrences = nil

    wildcard
  end
end