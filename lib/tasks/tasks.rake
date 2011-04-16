namespace :dpc do
  task :import_xmls => :environment do
    num_imported = 0

    Document.transaction do
      Document.delete_all
      Sentence.delete_all
      Word.delete_all
      WordFlag.delete_all

      Dir[File.join(RAILS_ROOT, "data/*")].each do |folder|
        if File.directory? folder
          Dir[File.join(folder, "*-nl-mtd.xml")].each do |metadata_file|
            contents_file = metadata_file.sub("nl-mtd", 'nl-tei')

            importer = Importer.new(metadata_file, contents_file)

            document = importer.execute

            num_imported += 1

            puts "Imported #{num_imported}: #{metadata_file} / #{document.title}"
          end
        end
      end
    end
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

    num_imported = 0

    Dir[File.join(RAILS_ROOT, "data/*")].each do |folder|
        if File.directory? folder
          Dir[File.join(folder, "*-nl-tei.xml")].each do |contents_file|
            # next unless File.basename(contents_file) == "dpc-bmm-001071-nl-tei.xml"

            next unless File.size? contents_file # zero bytes file?

            filename = File.basename(contents_file).sub(/-tei\.xml$/, "")

            document = Document.first(:conditions => {:filename => filename})

            raise "Could not find document for #{filename}" unless document

            aligner = TranslationAligner.new(document, folder)

            aligner.align

            num_imported += 1

            puts "Updated #{num_imported}: #{document.filename}"
          end
        end
      end
  end
end