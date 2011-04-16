class TranslationAligner

  def initialize(document, folder)
    @document = document
    @folder = folder
  end

  def align
    nl_xml = Hpricot.XML(File.read(xml_filename("nl-tei")))

    ['fr', 'en'].each do |language|
      if File.exist? xml_filename(language + "-tei")
        language_file = xml_filename("#{language}-tei")

        return if File.size(language_file) == 0

        untranslated_xml = Hpricot.XML(File.read(language_file))

        nl_sentences = read_sentences(nl_xml)
        untranslated_sentences = read_sentences(untranslated_xml)

        align_xml = Hpricot.XML(File.read(xml_filename("nl-#{language}-tei")))

        align_xml.at('linkGrp[@type="alignment"]').search("link").each do |link|
          nl_ids, untranslated_ids = link['targets'].split("; ")

          nl_ids.split(" ").each do |nl_id|
            nl_sentence = nl_sentences[nl_id]

            unless nl_sentences[nl_id]
              puts "Couldn't find sentence #{nl_id} in #{xml_filename("nl-tei")}!"
              next
            end

            untranslated = untranslated_ids.split(" ").collect do |untranslated_id|
              unless untranslated_sentences[untranslated_id]
                puts "Couldn't find sentence #{untranslated_id} in #{language_file}!"
                next
              end

              untranslated_sentences[untranslated_id][:original]
            end.join(" ")

            #puts nl_sentence[:original]
            #puts untranslated
            #puts ""

            sentence = @document.sentences.first(:conditions => {:position => nl_sentence[:position]})

            if sentence.untranslated.blank?
              sentence.untranslated = untranslated
            else
              sentence.untranslated_2 = untranslated
            end

            sentence.save!
          end
        end
      end
    end
  end

  def read_sentences(xml)
    sentences = {}

    xml.at("body").search('seg[@type="sent"]').each_with_index do |seg, sentence_index|
      original = seg.search('seg[@type="original"]').first.inner_text

      sentences[seg.at('s')['n']] = { :position => sentence_index, :original => original }
    end

    sentences
  end

  def xml_filename(suffix)
    File.join(@folder, @document.filename.sub(/-nl$/,'') + "-" + suffix + ".xml")
  end
end