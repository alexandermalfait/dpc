require 'java'

require 'jars/DPCSearcher-1.0.jar'
require 'jars/dependency/postgresql-8.3-603.jdbc4.jar'
require 'jars/dependency/guava-r09.jar'

include_class 'be.alex.dpc.SearchService'

if ENV['BOOT_SEARCH_ENGINE']
  SEARCH_SERVICE = SearchService.new
  SEARCH_SERVICE.read_data "data.txt"
end