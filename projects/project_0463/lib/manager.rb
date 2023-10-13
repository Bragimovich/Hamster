require_relative '../lib/manager'
require_relative '../lib/parser_spreadsheet'

class Manager < Hamster::Harvester
  def initialize
    super
  end

  def download
    #parser = ParserSpreadsheet.new
    parser.parse_races
    parser.parse_candidates
    parser.update_candidates_photo
    logger.info = "Success parsed and saved"
  end
end
