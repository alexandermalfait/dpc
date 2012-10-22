require 'java'

require 'jars/DPCSearcher-1.0.jar'
require 'jars/dependency/postgresql-8.3-603.jdbc4.jar'
require 'jars/dependency/guava-r09.jar'
require 'jars/dependency/jregex-1.2_01.jar'

include_class 'be.alex.dpc.SearchService'

if ENV['BOOT_SEARCH_ENGINE']
  SEARCH_SERVICE = SearchService.new
  SEARCH_SERVICE.progress_file_location = File.join(Rails.root, "public/current_progress.txt")
  SEARCH_SERVICE.data_location = "dumps"
end