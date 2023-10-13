require_relative 'keeper'
require_relative 'parser'

class Manager < Hamster::Harvester
  def store
    parser = Parser.new
    keeper = Keeper.new
    name = 'pdf_chatterton.gz'
    pdf_path  = peon.move_and_unzip_temp(file: name, from: 'file')
    parse_pdf = parser.parse(pdf_path)
    keeper.store(parse_pdf)
  end
end
