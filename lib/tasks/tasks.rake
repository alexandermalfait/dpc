namespace :dpc do
  task :import_xmls => :environment do
    num_imported = 0

    Document.transaction do
      %w(document sentence word word_flag flag word_type word_word).each do |table|
        puts "Clearing #{table}"

        Word.connection.execute("TRUNCATE #{table}")

        Word.connection.execute("SELECT setval('#{table}_id_seq', 1)")
      end

      Importer.drop_indexes

      require "benchmark"

      puts "Importing XML"

      folders = Dir[File.join(RAILS_ROOT, "data/*")].find_all { |file| File.directory?(file) }

      reporter = SpeedReporter.new("words")

      folders.each do |folder|
        Dir[File.join(folder, "*-mtd.xml")].each do |metadata_file|
          #next if num_imported > 300

          contents_file = metadata_file.sub("-mtd", '-tei')

          unless File.size(metadata_file) == 0 || File.size(contents_file) == 0
            importer = Importer.new(metadata_file, contents_file)

            document = importer.execute

            num_imported += 1

            puts "Imported #{num_imported}: #{metadata_file} / #{document.title}"

            reporter.processed(importer.num_words_imported)
          end
        end
      end

      Importer.create_indexes
    end
  end

  task :list_french_word_types => :environment do
    analyses = []

    Dir[File.join(RAILS_ROOT, "data/*")].each do |folder|
      if File.directory? folder
        puts "Checking folder #{folder}"

        Dir[File.join(folder, "*-fr-tei.xml")].each do |contents_file|
          puts "Reading #{contents_file}"

          contents = Hpricot.XML(File.read(contents_file))

          contents.search("w").each do |word|
            analyses << word['ana'] unless analyses.include?(word['ana'])
          end
        end
      end
    end

    puts analyses.sort.join("\n")
  end


  task :re_import_metadata => :environment do
    Document.transaction do
      num_imported = 0

      Dir[File.join(RAILS_ROOT, "data/*")].each do |folder|
        if File.directory? folder
          Dir[File.join(folder, "*-nl-mtd.xml")].each do |metadata_file|
            contents_file = metadata_file.sub("nl-mtd", 'nl-tei')

            next unless File.size? contents_file # zero bytes file?

            filename = File.basename(metadata_file).sub(/-mtd\.xml$/, "")

            document = Document.first(:conditions => {:filename => filename})

            raise "Could not find document for #{filename}" unless document

            importer = Importer.new(metadata_file, contents_file)

            importer.update_document(document)

            num_imported += 1

            puts "Updated #{num_imported}: #{metadata_file} / #{document.title}"
          end
        end
      end
    end
  end

  task :import_untranslated => :environment do
    Sentence.update_all("untranslated = '', untranslated_2 = ''")

    reporter = SpeedReporter.new("sentences")
    reporter.report_every = 1

    num_imported = 0

    metadata_pattern = /(.*)-([a-z]{2})-([a-z]{2})-tei\.xml/

    Dir[File.join(RAILS_ROOT, "data/*")].each do |folder|
      if File.directory? folder
        Dir[File.join(folder, "*")].find_all { |file| file.match(metadata_pattern) }.each do |metadata_file|
          match = metadata_file.match(metadata_pattern)

          basename = match[1]
          left_language = match[2]
          right_language = match[3]

          left_language_file = "#{basename}-#{left_language}-tei.xml"
          right_language_file = "#{basename}-#{right_language}-tei.xml"

          next unless File.size?(metadata_file) && File.size?(left_language_file) && File.size?(right_language_file) # zero bytes file?


          left_document_name = "#{File.basename(basename)}-#{left_language}"
          left_document = Document.first(:conditions => {:filename => left_document_name})
          raise "Could not find document for #{left_document_name}" unless left_document

          right_document_name = "#{File.basename(basename)}-#{right_language}"
          right_document = Document.first(:conditions => {:filename => right_document_name})
          raise "Could not find document for #{right_document_name}" unless right_document

          aligner = TranslationAligner.new(left_language_file, right_language_file, metadata_file, left_document, false)
          aligner.align

          reporter.processed(aligner.sentences_imported)

          aligner = TranslationAligner.new(right_language_file, left_language_file, metadata_file, right_document, true)
          aligner.align

          reporter.processed(aligner.sentences_imported)

          num_imported += 1

          puts "Updated #{num_imported}: #{left_document.filename}"
        end
      end
    end
  end

  task :re_run_searches => :environment do
    excel_filename = 'C:\Users\Alex\Desktop\DPC\alle data BN 04 04 2011.xls'
    folder = File.join( File.dirname(excel_filename), "alle data BN 04 04 2011")

    workbook = ExcelWorkBook.new(excel_filename)

    list = workbook.worksheet(0).list_by_header

    list.group_by { |row| row['Zoektermen'] }.each do |search, rows|
      name = rows.first['Benaming']

      puts "Re-running search #{name}"

      term_params = ::SearchController.parse_search_to_params(search)

      search = SearchController.convert_params_to_search term_params

      search_result = SEARCH_SERVICE.run_search(search)

      exporter = ExcelExporter.new(search_result.sentence_ids, { :search_name => name, :term => term_params })

      excel = exporter.get_excel do |row|
        if rows.find { |existing_row| row[3] == existing_row['Zin + POS'] }
          row << "r"
        end
      end

      target = File.join(folder, name + ".xls")
      file_index = 1

      while File.exist?(target)
        file_index += 1

        target = File.join(folder, "#{name}_#{file_index}.xls")
      end

      File.open(target, "wb") do |target_file|
        target_file.write excel.excel_content
      end
    end
  end

end