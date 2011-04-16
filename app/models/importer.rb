require 'hpricot'

class

Importer

  def initialize(metadata_file, contents_file)
    @metadata_file = metadata_file
    @contents_file = contents_file
  end

  def execute
    metadata = Hpricot.XML(File.read(@metadata_file))
    contents = Hpricot.XML(File.read(@contents_file))

    document = read_document(contents, metadata, Document.new)

    read_words(document, contents)
  end

  def update_document(document)
    metadata = Hpricot.XML(File.read(@metadata_file))
    contents = Hpricot.XML(File.read(@contents_file))

    read_document(contents, metadata, document)
  end

  def read_document(contents, metadata, document)
    meta_text = metadata.at("metaText")

    document.title = meta_text.at("TextUnitTitle").inner_text
    document.language = meta_text['lang']

    if document.title == ""
      document.title = meta_text.at("TitlePublication").inner_text
    end

    document.filename = contents.at("teiHeader").at("fileDesc").at("titleStmt").at("title").inner_text

    document.author = meta_text.at("Author").inner_text 

    publishing_info = meta_text.at("PublishingInfo")
    document.publisher = publishing_info.at("Publisher").inner_text
    document.publication_date = publishing_info.at("datePublication").inner_text
    document.original_publication_date = publishing_info.at("originalDatePublication").inner_text

    document.outcome = meta_text.at("Outcome").inner_text
    document.text_type = meta_text.at("TextType").inner_text
    document.text_subtype = meta_text.at("TextSubType").inner_text
    document.domain = meta_text.at("Domain").inner_text
    document.keywords = meta_text.at("Keywords1").inner_text
    document.ipr = meta_text.at("IPR").inner_text
    document.type_of_institution = meta_text.at("TypeOfInstitution").inner_text
    document.intended_audience = meta_text.at("IntendedAudience").inner_text

    meta_trans = metadata.at("metaTrans")

    document.original_language = meta_trans.at("Original")['lang']
    document.intermediate_language = meta_trans.at("Intermediate").inner_text
    document.translated_language = meta_trans.at("Translated").inner_text
    document.translation_mode = meta_trans.at("Mode").inner_text

    document.save!

    document
  end

  def read_words(document, contents)
    contents.at("body").search('seg[@type="sent"]').each_with_index do |seg, sentence_index|
      original = seg.search('seg[@type="original"]').first.inner_text

      Sentence.connection.execute "INSERT INTO sentence (document_id, position, original) VALUES(#{document.id}, #{sentence_index}, '#{e(original)}')"
      sentence_id = Sentence.connection.select_value "SELECT currval('sentence_id_seq')"

      seg.search('w').each_with_index do |w, word_index|
        analysis = w['ana'].match(/^([A-Z]+)\((.*)\)$/)

        analysis ||= [ "", "/", "" ]

        Word.connection.execute "
          INSERT INTO word (sentence_id, position, word, lemma, word_type)
          VALUES(#{sentence_id}, #{word_index}, '#{e(w.inner_text)}', '#{e(w['lemma'])}', '#{analysis[1]}')
        "

        word_id = Word.connection.select_value "SELECT currval('word_id_seq')"

        analysis[2].split(",").each_with_index do |flag, flag_index|
          if flag && flag != ""
            WordFlag.connection.execute "INSERT INTO word_flag (word_id, position, flag) VALUES (#{word_id}, #{flag_index}, '#{flag}')"
          end
        end
      end
    end
  end

  def e(string)
    string.gsub(/['"\\]/,'\\\\\0')
  end
end