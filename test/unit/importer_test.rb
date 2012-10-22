require 'test/unit'
require "./app/models/importer.rb"

class ImporterTest < Test::Unit::TestCase

  def test_dutch_analysis
    importer = Importer.new(nil, nil)

    analysis = importer.analyze("N(A,B,C,DE)", "nl")

    assert analysis[:type] == "N"

    assert_equal analysis[:flags], ["A","B","C","DE"]
  end

  def test_french_analysis
    importer = Importer.new(nil, nil)

    analysis = importer.analyze("Ncms", "fr")

    assert analysis[:type] == "N"

    assert_equal analysis[:flags], ["NTC","NGM","NNS"]
  end

  def test_french_composite_analysis
    importer = Importer.new(nil, nil)

    analysis = importer.analyze("Sp+Da-mp-d", "fr")

    assert analysis[:type] == "SD"

    assert_equal analysis[:flags], ["STP","DTA","DP-","DGM","DNP","DO-","DAD"]
  end
end
