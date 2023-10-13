# frozen_string_literal: true

require_relative 'scraper'
require_relative 'keeper'
require_relative 'parser'

class Manager < Hamster::Harvester
  attr_accessor :parser, :keeper, :scraper

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def download
    start_url = "https://polkinmates.polkcountyiowa.gov/Inmates/Current"
    main_page = scraper.main_page(start_url)
    detail_page_links = parser.get_detail_page(main_page)
    scraper.save_html(detail_page_links, keeper.run_id)
  end

  def store
    inmates = peon.list(subfolder: keeper.run_id.to_s)
    data_inmates = []
    inmates.each do |inmate|
      inmate_details = parser.parse_inmate_details(inmate, keeper.run_id.to_s)
      dirname = "#{storehouse}/store/#{keeper.run_id}/"
      data_inmates << inmate_details
      File.delete(dirname + inmate) if File.exist?(dirname + inmate)
    end
    keeper.insert_record(data_inmates)
    keeper.mark_deleted
    keeper.finish
  end
end
