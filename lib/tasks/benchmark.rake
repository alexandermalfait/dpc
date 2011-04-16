require 'benchmark'

namespace :dpc do
  namespace :benchmark do
    task :read_all_to_memory => :environment do
      limit = 1000_000

      Benchmark.bm do |bm|
        bm.report "read" do
          words = Word.connection.execute "SELECT * FROM word LIMIT #{limit}"
        end
      end
    end
  end
end