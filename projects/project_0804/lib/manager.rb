require_relative 'parser'
require_relative 'keeper'
class Manager < Hamster::Harvester
  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def store_csv
    name_csv  = peon.give_list(subfolder: 'csv')
    name_csv.each do |file|
      csv_path  = peon.give(file: file, subfolder: "csv")
      csv_data  = @parser.parse_csv(csv_path, file)
      @keeper.store(csv_data)
    end
  end

  def store_pdf
    name_pages = peon.give_list(subfolder: 'pdf')
    name_pages.each do |name|
      pdf_path = peon.copy_and_unzip_temp(file: name, from: "pdf")
      pdf_info = @parser.parse_pdf(pdf_path, name)
      @keeper.store(pdf_info)
    end
  end
end
