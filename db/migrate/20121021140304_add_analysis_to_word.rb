class AddAnalysisToWord < ActiveRecord::Migration
  def self.up
    change_table :word do |t|
      t.string :analysis
    end
  end

  def self.down
    change_table :word do |t|
      t.remove :analysis
    end
  end
end
