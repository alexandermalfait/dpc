class Word < ActiveRecord::Base
  belongs_to :sentence

  has_many :flags, :class_name => "WordFlag"

  def self.word_types
    ["/", "ADJ", "BW", "LET", "LID", "N", "SPEC", "TSW", "TW", "VG",  "VNW",  "VZ", "WW" ]
  end
end
