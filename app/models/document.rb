class Document < ActiveRecord::Base
  has_many :sentences

  def self.counts_per_language
    languages = {}

    Document.connection.select_rows("SELECT language, COUNT(*) FROM document GROUP BY language ORDER BY language").each do |row|
      languages[row[0]] = row[1]
    end

    languages
  end
end
