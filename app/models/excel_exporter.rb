class ExcelExporter

  def initialize(sentence_ids, options)
    @sentence_ids = sentence_ids
    @options = options
  end

  def get_excel
    excel = PoiExcelWriter.new

    excel.create_sheet "Resultaten"

    excel.write_row [
      "Benaming","Zoektermen","Zin", "Zin + POS", "File", "Titel", "Taal", "Auteur", "Uitgever", "Publicatie Datum", "Orig Publicatie Datum",
      "Text Type", "Subtype", "Domein", "Keyword", "Type instituut", "Doelpubliek", "Doel", "Brontaal", "Doeltaal", "Intermediate", "Soort Vertaling",
      "N Woorden", "N Zinnen", "Context Voor", "Context Zin", "Context Na", "Origineel", "Origineel 2", "Relevantie"
    ], :bold

    index = 0

    terms_description = get_terms_description

    @sentence_ids.to_a.in_groups_of(100).each do |group|
      sentences = Sentence.connection.execute("SELECT id, original, document_id, position, untranslated, untranslated_2 FROM sentence WHERE id IN (" + group.find_all{ |it| it.present? }.join(',') + ") ORDER BY document_id, position")

      documents_by_id = Document.connection.execute("
        SELECT *, (SELECT COUNT(*) FROM sentence WHERE document_id = document.id) AS num_sentences
        FROM document
        WHERE id IN (" + sentences.collect { |it| it['document_id'] }.sort.uniq.join(',') + ")
      ").group_by { |it| it['id']}

      words = Word.connection.execute("SELECT id, word, word_type, lemma, sentence_id FROM word WHERE sentence_id IN (" + sentences.collect { |it| it['id'] }.join(',') + ") ORDER BY sentence_id, position")

      words_per_sentence = words.group_by { |it| it['sentence_id'] }

      flags_per_word = WordFlag.connection.execute("SELECT word_id, flag FROM word_flag WHERE word_id IN (" + words.collect { |it| it['id'] }.join(',') + ") ORDER BY word_id, position").group_by { |it| it['word_id'] }

      sentences.each do |sentence|
        index += 1

        if index % 10 == 0
          puts "Exported to excel: #{index} / #{@sentence_ids.length}"

          report_progress("Excel: #{index}/#{@sentence_ids.length}")
        end

        document = documents_by_id[sentence['document_id']][0]

        words_for_sentence = words_per_sentence[sentence['id']]

        row = []

        row << @options[:search_name]

        row << terms_description

        row << sentence['original']
        
        row << words_for_sentence.collect do |word|
          flags = ( flags_per_word[word['id']] || [] ).collect { |f| f['flag'] }.join(',')

          "#{word['word']} #{word['word_type']}(#{flags};#{word['lemma']})"
        end.join(" ")

        row << document['filename']
        row << document['title']
        row << document['language']
        row << document['author']
        row << document['publisher']
        row << document['publication_date']
        row << document['original_publication_date']
        row << document['text_type']
        row << document['text_subtype']
        row << document['domain']
        row << document['keywords']
        row << document['type_of_institution']
        row << document['intended_audience']
        row << document['outcome']
        row << document['original_language']
        row << document['translated_language']
        row << document['intermediate_language']
        row << document['translation_mode']
        row << words_for_sentence.length
        row << document['num_sentences']

        if @options[:show_sentences_before].present?
          number = @options[:show_sentences_before].to_i
          position = sentence['position']

          row << Sentence.connection.select_values(
            "SELECT original FROM sentence WHERE document_id = #{document['id']} AND position BETWEEN #{position - number} AND #{position - 1} ORDER BY position"
          ).join(" ")
        else
          row << ""
        end

        row << sentence['original']

        if @options[:show_sentences_after].present?
          number = @options[:show_sentences_after].to_i
          position = sentence['position']

          row << Sentence.connection.select_values(
            "SELECT original FROM sentence WHERE document_id = #{document['id']} AND position BETWEEN #{position + 1} AND #{position + number} ORDER BY position"
          ).join(" ")
        else
          row << ""
        end

        row << sentence['untranslated']
        row << sentence['untranslated_2']

        yield row if block_given?

        excel.write_row row
      end
    end

    report_progress("Done")

    excel
  end

  def report_progress(message)
    File.open(File.join(Rails.root, "public/current_progress.txt"), "w") do |f|
      f.write message
    end
  end

  def get_terms_description
    term_descriptions = []

    terms = @options[:term]

    terms = terms.values if terms.kind_of?(Hash)

    terms.sort_by { |term| term[:index].to_i }.each do |term_params|
      map = {}

      map['Woord'] = term_params[:word].downcase if term_params[:word].present?

      map['Lemma'] = term_params[:lemma].downcase if term_params[:lemma].present?

      if term_params[:word_types]
        map['Types'] = term_params[:word_types].join(',')
      end

      if term_params[:flags].present?
        map['Flags'] = "#{term_params[:flags]}(#{term_params[:flags_type]})"
      end

      map['FlagsExclude'] = term_params[:exclude_flags] if term_params[:exclude_flags].present?

      map['Afstand'] = term_params[:max_distance].to_i if term_params[:max_distance].present?

      map['Eerste'] = "Ja" if term_params[:position_type] == "first"

      map['Laatste'] = "Ja" if term_params[:position_type] == "last"

      map['Negatief'] = "Ja" if term_params[:exclude_term].present?


      description = []

      map.each do |key, value|
        description << "#{key}=#{value}"
      end

      term_descriptions << description.join(" & ")
    end

    term_descriptions.join(" + ")
  end
end