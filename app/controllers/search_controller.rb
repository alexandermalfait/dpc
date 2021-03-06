include_class 'be.alex.dpc.Search'
include_class 'be.alex.dpc.SearchTerm'

class SearchController < ApplicationController

  MAX_REGEX_HITS = 1000

  def index
    @languages = Document.counts_per_language
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

    unless params[:languages].present?
      render :text => "<strong>Oeps, geen taal aangeduid</strong>" and return
    end

    search = SearchController.convert_params_to_search params[:term].values, params[:languages]

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
    search = SearchController.convert_params_to_search params[:term].values, params[:languages]

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

  def self.convert_params_to_search(terms, languages)
    search = Search.new

    search.languages = languages

    terms.sort_by { |term| term[:index].to_i }.each do |term_params|
      term = SearchTerm.new

      term.word = term_params[:word].downcase if term_params[:word].present?
      term.word_regex = true if term_params[:word_regex].present?

      if term_params[:lemma].present?
        term.lemmas = convert_to_java_array(term_params[:lemma])
      end

      if term_params[:flags].present?
        term.flags = convert_to_java_array(term_params[:flags])
        term.flags_or_mode = term_params[:flags_type] == "OR"
      end

      if term_params[:exclude_flags].present?
        term.exclude_flags = convert_to_java_array(term_params[:exclude_flags])
        term.excluded_flags_or_mode = term_params[:exclude_flags_type] == "OR"
      end

      if term_params[:word_types]
        term.word_type_ids = term_params[:word_types].collect(&:to_i).to_java(:int)
      end

      case term_params[:occurrence_type]
        when "once"
          term.min_occurrences = 1
          term.max_occurrences = 1
        when "wildcard"
          term.min_occurrences = 0
          term.max_occurrences = nil
        when "range"
          term.min_occurrences = term_params[:min_occurrences].to_i
          term.max_occurrences = term_params[:max_occurrences].to_i
      end

      term.invert_term = true if term_params[:invert_term].present?

      logger.info "Term: word = #{term.word}, lemma = #{term.lemmas}, flags = #{term.flags.to_a}, types = #{term.word_types.to_a}"

      search.terms << term
    end

    search
  end

  def self.convert_to_java_array(string)
    string.downcase.split(/\s*,\s*/).find_all { |it| it.present? }.to_java(:string)
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
