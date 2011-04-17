include_class 'be.alex.dpc.Search'
include_class 'be.alex.dpc.SearchTerm'

class SearchController < ApplicationController

  MAX_REGEX_HITS = 1000

  def index
    
  end

  def search_term
    @index = params[:index].to_i
    @field_name = "term[#{Time.now.to_f.to_s.sub('.','')}]"
    @search = {}

    render :layout => false
  end

  def search_preview
    params[:term].values.each do |term_vals|
      if term_vals[:word_regex].present?
        count = WordWord.count(:conditions => [ "word ~ ?", term_vals[:word].downcase ])

        if count > MAX_REGEX_HITS
          render :text => "<strong>Regex '#{term_vals[:word]}' matcht #{count} woorden. Maximaal #{MAX_REGEX_HITS} woord matches zijn toegestaan via regex.</strong>" and return
        end
      end
    end

    search = SearchController.convert_params_to_search params[:term].values

    @search_result = SEARCH_SERVICE.run_search(search)

    @num_hits = @search_result.size

    @sentences = Sentence.all(
      :conditions => [ "sentence.id IN (?)", @search_result.sentence_ids.to_a[0..50]],
      :include => { :words => :flags }
    )

    @context = { :before => {}, :after => {} }

    if params[:show_sentences_before].present? || params[:show_sentences_after].present?
      @sentences.each do |sentence|
        if params[:show_sentences_before].present?
          @context[:before][sentence] = sentence.sentences_before(params[:show_sentences_before].to_i)
        end

        if params[:show_sentences_after].present?
          @context[:after][sentence] = sentence.sentences_after(params[:show_sentences_after].to_i)
        end
      end
    end

    render :layout => false
  end

  def excel_export
    search = SearchController.convert_params_to_search params[:term].values

    search_result = SEARCH_SERVICE.run_search(search)

    exporter = ExcelExporter.new(search_result.sentence_ids, params)

    if params[:search_name].present?
      filename = "#{params[:search_name]}.xls"
    else
      filename = "export.xls"
    end

    send_data(
      exporter.get_excel.excel_content,
      :filename => filename, :type => "application/vnd.ms-excel", :disposition => "attachment"
    )
  end

  def self.convert_params_to_search(terms)
    search = Search.new

    terms.sort_by { |term| term[:index].to_i }.each do |term_params|
      term = SearchTerm.new

      term.word = term_params[:word].downcase if term_params[:word].present?
      term.word_regex = true if term_params[:word_regex].present?


      term.lemma = term_params[:lemma].downcase if term_params[:lemma].present?

      if term_params[:flags].present?
        term.flags = term_params[:flags].downcase.split(/\s*,\s*/).find_all { |it| it.present? }.to_java(:string)
        term.flags_or_mode = term_params[:flags_type] == "OR"
      end

      if term_params[:exclude_flags].present?
        term.exclude_flags = term_params[:exclude_flags].downcase.split(/\s*,\s*/).find_all { |it| it.present? }.to_java(:string)
      end

      if term_params[:word_types]
        term.word_types = term_params[:word_types].to_java(:string) 
      end

      term.maximum_distance_from_last_match = term_params[:max_distance].to_i if term_params[:max_distance].present?

      term.first_in_sentence = term_params[:position_type] == "first"

      term.last_in_sentence = term_params[:position_type] == "last"

      term.exclude_term = true if term_params[:exclude_term].present?

      logger.info "Term: word = #{term.word}, lemma = #{term.lemma}, flags = #{term.flags.to_a}, types = #{term.word_types.to_a}, distance = #{term.maximum_distance_from_last_match}"

      search.terms << term
    end

    search
  end

  def self.parse_search_to_params(description)
    params = []

    terms = description.split(' + ')

    terms.each_with_index do |term_string, term_index|
      term_param = { :index => term_index }

      parts = term_string.split(' & ')

      parts.each do |part|
        match = part.match(/(.+)=(.+)/)

        field = match[1]
        value = match[2]

        raise "Couldn't match #{part}" unless match

        case field
          when "Woord"
            term_param[:word] = value
            term_param[:word_regex] = value.include?("^") || value.include?("$") || value.include?("*") || value.include?("(") || value.include?("|")
          when "Lemma"
            term_param[:lemma] = value
          when "Types"
            term_param[:word_types] = value.split(',')
          when "Flags"
            flags_match = value.match(/(.+)\((.+)\)/)

            term_param[:flags] = flags_match[1]
            term_param[:flags_type] = flags_match[2]
          when "FlagsExclude"
            term_param[:exclude_flags] = value
          when "Afstand"
            term_param[:max_distance] = value
          when "Eerste"
            term_param[:position_type] = "first"
          when "Laatste"
            term_param[:position_type] = "last"
          when "Negatief"
            term_param[:exclude_term] = "true"
        end
      end

      params << term_param
    end

    params
  end
end
