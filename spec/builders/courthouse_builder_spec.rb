require 'spec_helper'

module RapSheetParser
  RSpec.describe CourthouseBuilder do
    it 'translates courthouse names to display names' do
      text = <<~TEXT
        info
        * * * *
        COURT: NAME7OZ
        19820915 CASC SN JOSE

        CNT: 001 #45      6
        DISPO:CONVICTED
        * * * END OF MESSAGE * * *
      TEXT

      tree = RapSheetGrammarParser.new.parse(text)
      courthouse_node = tree.cycles[0].events[0].courthouse
      expect(described_class.new(courthouse_node, logger: nil).build).to eq 'CASC San Jose'
    end

    it 'displays unknown courthouse names directly and logs warnings' do
      text = <<~TEXT
        info
        * * * *
        COURT: NAME7OZ
        19820915 CASC ANYTOWN USA

        CNT: 001 #45      6
        DISPO:CONVICTED
        * * * END OF MESSAGE * * *
      TEXT

      log = StringIO.new
      logger = Logger.new(log)
      tree = RapSheetGrammarParser.new.parse(text)
      courthouse_node = tree.cycles[0].events[0].courthouse
      expect(described_class.new(courthouse_node, logger: logger).build).to eq 'CASC ANYTOWN USA'

      expect(log.string).to include 'WARN -- : Unrecognized courthouse:'
      expect(log.string).to include 'WARN -- : CASC ANYTOWN USA'
    end

    it 'correctly logs warning when an unknown courthouse begins with text matching a known courthouse' do
      text = <<~TEXT
        info
        * * * *
        COURT: NAME7OZ
        19820915 CASC SN JOSE CENTRAL

        CNT: 001 #45      6
        DISPO:CONVICTED
        * * * END OF MESSAGE * * *
      TEXT

      log = StringIO.new
      logger = Logger.new(log)
      tree = RapSheetGrammarParser.new.parse(text)
      courthouse_node = tree.cycles[0].events[0].courthouse
      expect(described_class.new(courthouse_node, logger: logger).build).to eq 'CASC SN JOSE CENTRAL'

      expect(log.string).to include 'WARN -- : Unrecognized courthouse:'
      expect(log.string).to include 'WARN -- : CASC SN JOSE CENTRAL'
    end

    it 'strips periods from courthouse names' do
      text = <<~TEXT
        info
        * * * *
        COURT: NAME7OZ
        19820915 CAMC LOS .ANGELES METRO

        CNT: 001 #45      6
        DISPO:CONVICTED
        * * * END OF MESSAGE * * *
      TEXT

      tree = RapSheetGrammarParser.new.parse(text)
      courthouse_node = tree.cycles[0].events[0].courthouse
      expect(described_class.new(courthouse_node, logger: nil).build).to eq 'CAMC Los Angeles Metro'
    end
  end
end
