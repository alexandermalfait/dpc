class TranslationAligner

  def initialize(left_document, right_document, mapping_document, document_record)
    @left_document = left_document
    @right_document = right_document
    @mapping_document = mapping_document
    @document_record = document_record
  end

  def align
    languages = %w(nl fr en)

    left_xml = Hpricot.XML(File.read(@left_document))
    right_xml = Hpricot.XML(File.read(@right_document))
    align_xml = Hpricot.XML(File.read(@mapping_document))

    left_sentences = read_sentences(left_xml)
    right_sentences = read_sentences(right_xml)

    puts left_sentences.inspect
    puts right_sentences.inspect

    align_xml.at('linkGrp[@type="alignment"]').search("link").each do |link|
      left_ids, right_ids = link['targets'].split("; ")

      left_ids.split(" ").each do |left_id|
        left_sentence = left_sentences[left_id]

        unless left_sentences[left_id]
          puts "Couldn't find sentence #{left_id} in #{xml_filename("nl-tei")}!"
          next
        end

        matching_right_sentences = right_ids.split(" ").collect do |right_id|
          unless right_sentences[right_id]
            puts "Couldn't find sentence #{right_id.inspect} in #{@right_document}!"
            next
          end

          right_sentences[right_id][:original]
        end.join(" ")

        puts left_sentence[:original]
        puts matching_right_sentences
        puts ""

        left_sentence_record = @document_record.sentences.first(:conditions => {:position => left_sentence[:position]})

        unless left_sentence_record
          raise "Couldn't find sentence #{left_sentence[:position]} in document #{@document.filename} (#{@document.id})"
        end

        if left_sentence_record.untranslated.blank?
          left_sentence_record.untranslated = matching_right_sentences
        else
          left_sentence_record.untranslated_2 = matching_right_sentences
        end

        left_sentence_record.save!
      end
    end
  end

  def read_sentences(xml)
    sentences = {}

    xml.at("body").search('seg[@type="sent"]').each_with_index do |seg, sentence_index|
      original = seg.search('seg[@type="original"]').first.inner_text

      sentences[seg.at('s')['n']] = {:position => sentence_index, :original => original}
    end

    sentences
  end

  def xml_filename(suffix)
    File.join(@folder, @document.filename.sub(/-nl$/, '') + "-" + suffix + ".xml")
  end
end