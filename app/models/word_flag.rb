class WordFlag < ActiveRecord::Base
  belongs_to :word

  def to_s
    flag
  end
end
