# frozen_string_literal: true

require_relative './scraper'
require_relative './parser'
require_relative './keeper'
require_relative '../../../lib/ashman/ashman.rb'

URL = "https://data.illinois.gov/dataset/professional-licensing"

class IlProfLicensesManager < Hamster::Harvester
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
  end

  def download
    link = @parser.get_file_link(@scraper.get_source(URL))
    @csv_file = @scraper.download_csv(link)
  end

  def store
    @csv_file ||= Dir[@scraper.storehouse + "store/*"].sort[-1]
    Keeper.new.store_to_db(@csv_file)
    @scraper.clear
  end

  def test
    ashman = Hamster::Ashman.new({:aws_opts => {}, account: :loki, bucket: 'loki-files'})
    list = ashman.list({prefix: 'tasks/scrape_tasks/st00359/'})
    filenames = list[:contents].map {|el| list.name + "/" + el.key}
    filenames.each {|line| logger.info(line)}
  end
end
