class TranslationAligner

  attr_reader :sentences_imported

  def initialize(left_document, right_document, mapping_document, document_record, right_to_left)
    @left_document = left_document
    @right_document = right_document
    @mapping_document = mapping_document
    @document_record = document_record
    @right_to_left = right_to_left

    @sentences_imported = 0
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
      if @right_to_left
        right_ids, left_ids = link['targets'].split("; ")
      else
        left_ids, right_ids = link['targets'].split("; ")
      end


      left_ids.split(" ").each do |left_id|
        left_sentence = left_sentences[left_id]

        unless left_sentences[left_id]
          puts "Couldn't find sentence #{left_id} in #@left_document!"
          next
        end

        matching_right_sentences = right_ids.split(" ").collect do |right_id|
          unless right_sentences[right_id]
            puts "Couldn't find sentence #{right_id.inspect} in #@right_document!"
            next
          end

          right_sentences[right_id][:original]
        end.join(" ")

        left_sentence_record = @document_record.sentences.first(:conditions => {:position => left_sentence[:position]})

        unless left_sentence_record
          raise "Couldn't find sentence #{left_sentence[:position]} in document #{@document.filename} (#{@document.id})"
        end

        if left_sentence_record.untranslated.blank?
          left_sentence_record.update_attribute :untranslated, matching_right_sentences
        else
          left_sentence_record.update_attribute :untranslated_2, matching_right_sentences
        end

=begin
        puts File.basename(@left_document) + " => " + File.basename(@right_document)
        puts left_sentence_record.original
        puts left_sentence_record.untranslated
        puts left_sentence_record.untranslated_2
        puts ""
=end

        left_sentence_record.save!

        @sentences_imported += 1
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