namespace :dpc do
  namespace :batch_search do
    task :nouns => :environment do
      words = %w(Table Management Website Partner Type Article Speaker Ceo Budget Manager Site Software Marketing Fax Job btw Usd e-mail nanobodies team ict bizz trend gsm computer web coach service displays follow-up goodwill chips led knowhow display stress feedback mix handiweb club link unit dreadlocks mail interview pc site websites nanobody partnership trainer ic's spin-off timing real indicator label interface r&d consultant director audit tools investment engineering buy-out marketer deal performers equity database cock consolidatiegoodwill mri start-up leasing gsm warrant buy-out holding sun coreoptics stroke branding operator server input masterplan sms controllers deadline catering indoor actuals charter meeting incentive target master return processing minifizz e-mail managing roots speech guidelines scooter royalty's benchmark retail songs governance privacy microcontroller venture wafers hole businessmodel goal rituals producer made buzz consumer)

      searcher = BatchSearcher.new(words, ["NL-BE"], [31], "N")

      searcher.execute
    end

    task :verbs => :environment do
      words = %w(Linken Trainen Printen Coachen Checken Scannen Runnen)

      searcher = BatchSearcher.new(words, ["NL-BE"], [32], "V")

      searcher.execute
    end
  end

end