require 'hpricot'

class

Importer

  attr_reader :num_words_imported

  def initialize(metadata_file, contents_file)
    @metadata_file = metadata_file
    @contents_file = contents_file
    @num_words_imported = 0

    @french_tag_orders = {
        'N' => 'TGN',
        'V' => 'TMEPNG',
        'A' => 'TDGN',
        'P' => 'TPGNCO',
        'D' => 'TPGNOA',
        'R' => 'TDGN',
        'S' => 'T',
        'C' => 'T',
        'I' => 'X',
        'F' => '?',
        ' ' => 'FW',
    }
  end

  def execute
    metadata = Hpricot.XML(File.read(@metadata_file))
    contents = Hpricot.XML(File.read(@contents_file))

    document = read_document(contents, metadata, Document.new)

    read_words(document, contents)

    document
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
    language = @metadata_file.match(/([a-z]{2})-mtd\.xml/)[1]

    word_type_ids_map = WordType.all(:conditions => {:language => language}).inject({}) { |map, word_type| map[word_type.name] = word_type.id; map }
    flag_ids_map = Flag.all.inject({}) { |map, flag| map[flag.name] = flag.id; map }


    contents.at("body").search('seg[@type="sent"]').each_with_index do |seg, sentence_index|
      original = seg.search('seg[@type="original"]').first.inner_text

      sentence_id = Sentence.connection.select_value "
        INSERT INTO sentence (document_id, position, original) VALUES(#{document.id}, #{sentence_index}, '#{e(original)}') RETURNING id
      "

      seg.search('w').each_with_index do |w, word_index|
        analysis = analyze(w['ana'], language)

        word_text = w.inner_text

        word_word_id = Word.connection.select_value "SELECT id FROM word_word WHERE word = '#{e word_text.downcase}'"
        word_word_id ||= Word.connection.select_value "INSERT INTO word_word (word) VALUES('#{e(word_text.downcase)}') RETURNING id"

        word_type = analysis[:type]
        word_type_ids_map[word_type] ||= Word.connection.select_value "INSERT INTO word_type (name, language) VALUES('#{e word_type}', '#{e language}') RETURNING id"

        word_id = Word.connection.select_value "
          INSERT INTO word (sentence_id, position, word, word_id, lemma, word_type, word_type_id, analysis)
          VALUES(#{sentence_id}, #{word_index}, '#{e(word_text)}', #{word_word_id}, '#{e(w['lemma'])}', '#{e word_type}', '#{word_type_ids_map[word_type]}', '#{e w['ana']}')
          RETURNING id
        "
        analysis[:flags].each_with_index do |flag, flag_index|
          flag_values = []

          if flag && flag != ""
            flag = flag.downcase

            flag_ids_map[flag] ||= Word.connection.select_value "INSERT INTO flag (name) VALUES('#{e flag}') RETURNING id"

            flag_values << "(#{word_id}, #{flag_index}, '#{flag}', #{flag_ids_map[flag]})"
          end

          if flag_values.present?
            WordFlag.connection.execute "INSERT INTO word_flag (word_id, position, flag, flag_id) VALUES #{flag_values.join(',')}"
          end
        end

        @num_words_imported += 1
      end
    end
  end

  def analyze(text, language)
    case language
      when "nl"
        match = text.match(/^([A-Z]+)\((.*)\)$/)
        match ||= ["", "/", ""]

        {:type => match[1], :flags => match[2].split(',')}

      when "en"
        {:type => text, :flags => []}

      when "fr"
        types = []
        flags = []

        text.split('+').each do |word|
          chars = word.split("")

          type = chars.shift.upcase
          types << type

          chars.each_with_index do |flag, index|
            unless @french_tag_orders[type] && @french_tag_orders[type][index]
              puts "Couldn't find flag code #{index} in #{@french_tag_orders[type]} (ana #{text}, #{type})"
              next
            end

            flag_code = @french_tag_orders[type].split("")[index]

            flags << type + flag_code + flag.upcase
          end
        end

        {:type => types.join, :flags => flags }
      else
        raise "Unknown language #{language}"
    end
  end

  def e(string)
    string.gsub(/['"\\]/, '\\\\\0')
  end

  def self.create_indexes
    puts "Creating indexes"
    Word.connection.execute("CREATE INDEX index_word_flag_on_word_id ON word_flag USING btree (word_id);")
  end

  def self.drop_indexes
    puts "Dropping indexes"
    Word.connection.execute("DROP INDEX index_word_flag_on_word_id;")
  end

end