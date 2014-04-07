require 'java'

require 'jars/DPCSearcher-1.0.jar'
require 'jars/dependency/postgresql-8.3-603.jdbc4.jar'
require 'jars/dependency/guava-r09.jar'
require 'jars/dependency/jregex-1.2_01.jar'

java_import 'be.alex.dpc.SearchService'
java_import 'be.alex.dpc.DatabaseConfig'

if ENV['BOOT_SEARCH_ENGINE']
  database_config = DatabaseConfig.new
  database_config.host = "localhost"
  database_config.user = "postgres"
  database_config.password = "olifant"
  database_config.database = "dpc"

  SEARCH_SERVICE = SearchService.new

  SEARCH_SERVICE.progress_file_location = File.join(Rails.root, "public/current_progress.txt")
  SEARCH_SERVICE.data_location = "dumps"
  SEARCH_SERVICE.database_config = database_config
end