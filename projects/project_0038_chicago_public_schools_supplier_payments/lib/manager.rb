# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  DIR_MAIN = '../HarvestStorehouse/project_038/'

  def initialize
    super
    @keeper = Keeper.new
    @response
  end

  def download
    scraper = Scraper.new

    url = 'https://schoolinfo.cps.edu/ProcurementAPI/api/Supplier/GetSupplierPayments/'
    @response = scraper.load_page(url)
  end

  def store
    return Hamster.report(
      to: 'dmitiry.suschinsky',
      message: '#38 Chicago public schools supplier payments'
    ) if @response.class == NilClass

    parser = Parser.new
    records = parser.get_records(@response)
    parser.parse_data(records)

    @keeper.finish
  end

  def main(year)
    begin
      # SCRAPE_MAIN PART
      url = 'https://schoolinfo.cps.edu/ProcurementAPI/api/Supplier/GetSupplierPayments/'

      global_list_parser_chicago = Parser.new
      scrape = Scraper.new

      @response = scrape.load_page(url+year.to_s)
      array = global_list_parser_chicago.get_records(@response)
      global_list_parser_chicago.parse_data(array)

      dirname = create_dir(DIR_MAIN)
      pack_to_gz(dirname, year.to_s, @response.body)

      Hamster.report(to: 'Dmitiry Suschinsky', message: "End scrape process #38 for year: #{year}")
    rescue SystemExit, Interrupt, StandardError, ActiveRecord::ActiveRecordError => e
      Hamster.report(to: 'Dmitiry Suschinsky', message: "ERROR #38 year: #{year}\n#{e}")
    end
  end

  def new_array(search_value)
    array = []
    1.times do |i|
      array += ('a'..'z').collect { |e| search_value + e * (i + 1) }
    end
    array
  end

  def pack_to_gz(dir, name, html)
    Zlib::GzipWriter.open(gz_file(dir, name)) do |gz|
      gz.write(html)
    end
    File.rename(gz_file(dir, name), gz_file(dir, name))
  end

  def move_file(dir, name, new_dir)
    dirname = create_dir(dir)
    new_dirname = create_dir(new_dir)
    FileUtils.mv(gz_file(dirname, name), gz_file(new_dirname, name))
  end

  def create_dir(dir)
    # dirname = File.dirname("#{ENV['HOME']}/RubymineProjects/Hamster/#{self.class.name}/#{dir}/x")
    dirname = dir
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    dirname + '/'
  end

  def gz_file(dir, name)
    # create_dir(dir)
    dir + name.gsub(/\..+/, '') + '.gz'
  end

  def read_gz(dir)
    Zlib::GzipReader.open(dir, &:read)
  end
end
