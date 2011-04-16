class AddUntranslatedToSentence < ActiveRecord::Migration
  def self.up
    change_table :sentence do |t|
      t.text :untranslated
      t.text :untranslated_2
    end
  end

  def self.down
    change_table :sentence do |t|
      t.remove :untranslated
      t.remove :untranslated_2
    end
  end
end
