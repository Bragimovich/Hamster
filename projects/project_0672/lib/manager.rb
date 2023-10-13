# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @sub_folder = "PDF"
  end

  def main
    pdf_file = Dir[("#{storehouse}store/PDF/*pdf")].first
    puts "Processing file #{pdf_file} ..."
    reader = PDF::Reader.new(open(pdf_file))
    pdf_pages = reader.pages
    data_array = parser.pdf_parsing(pdf_pages)
    keeper.insert_data(data_array) 
    puts '***'*20, "Scrape - Done!", '***'*20
  end

  private
  attr_accessor :sub_folder, :keeper, :parser

end
