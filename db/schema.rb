# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121021140304) do

  create_table "document", :force => true do |t|
    t.string "filename"
    t.string "title",                     :limit => 1000
    t.string "author"
    t.string "publisher"
    t.date   "publication_date"
    t.string "outcome"
    t.string "text_type"
    t.string "text_subtype"
    t.string "domain"
    t.string "keywords"
    t.string "ipr"
    t.string "type_of_institution"
    t.string "intended_audience"
    t.string "original_language"
    t.string "intermediate_language"
    t.string "translated_language"
    t.string "translation_mode"
    t.string "language",                  :limit => 10
    t.date   "original_publication_date"
  end

  create_table "flag", :force => true do |t|
    t.string "name", :limit => 10, :null => false
  end

  create_table "lemma", :force => true do |t|
    t.string "lemma", :limit => 200, :null => false
  end

  add_index "lemma", ["lemma"], :name => "idx_lemma"

  create_table "sentence", :force => true do |t|
    t.integer "document_id",    :null => false
    t.integer "position",       :null => false
    t.text    "original"
    t.text    "untranslated"
    t.text    "untranslated_2"
  end

  create_table "test", :id => false, :force => true do |t|
    t.integer "id",   :limit => 10,  :null => false
    t.string  "text", :limit => 100
  end

  create_table "word", :force => true do |t|
    t.integer "sentence_id",                 :null => false
    t.integer "position",                    :null => false
    t.string  "word",         :limit => 200
    t.string  "lemma",        :limit => 200
    t.string  "word_type",    :limit => 30
    t.integer "lemma_id"
    t.integer "word_type_id"
    t.integer "word_id"
    t.string  "analysis"
  end

  create_table "word_flag", :force => true do |t|
    t.integer "word_id",                :null => false
    t.integer "position",               :null => false
    t.string  "flag",     :limit => 10
    t.integer "flag_id"
  end

  add_index "word_flag", ["word_id"], :name => "index_word_flag_on_word_id"

  create_table "word_type", :force => true do |t|
    t.string "name",     :limit => 100, :null => false
    t.string "language", :limit => 2
  end

  create_table "word_word", :force => true do |t|
    t.string "word", :limit => 200, :null => false
  end

  add_index "word_word", ["word"], :name => "idx_word_word"

end
