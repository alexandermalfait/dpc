class Sentence < ActiveRecord::Base
  belongs_to :document

  has_many :words, :order => :position

  def sentences_before(number)
    Sentence.all(
      :conditions => [ "document_id = ? AND position BETWEEN ? AND ?", document_id, position - number, position - 1 ],
      :order => :position
    )
  end

  def sentences_after(number)
    Sentence.all(
      :conditions => [ "document_id = ? AND position BETWEEN ? AND ?", document_id, position + 1, position + number ],
      :order => :position
    )
  end
end
