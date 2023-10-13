require_relative 'keeper'
require_relative 'scraper'
require_relative 'parser'

class Manager < Hamster::Harvester
  def initialize
    super
    @keeper = Keeper.new
  end

  def download
    keeper.status = 'scraping'
    scraper = Scraper.new(keeper)
    scraper.scrape
    message = "Success scraped schools: #{scraper.count}"
    report_message(message)
  end

  def store
    keeper.status = 'parsing'
    run_id        = keeper.run_id
    states        = peon.list(subfolder: "#{run_id}_schools")
    states.each do |state|
      schools_name = peon.give_list(subfolder: "#{run_id}_schools/#{state}")
      schools_name.each do |name|
        Hamster.logger.debug "#{name}".green

        page   = peon.give(file: name, subfolder: "#{run_id}_schools/#{state}")
        parser = Parser.new(html: page)
        school = parser.parse_school(keeper)
        keeper.save_school_director(school)
      end
    end

    keeper.finish
    message = "Success parsed a schools: #{keeper.count}"
    report_message(message)
  end

  private

  attr_accessor :keeper

  def report_message(message)
    Hamster.logger.info message.green
    Hamster.report(to: 'Eldar Eminov', message: message, use: :both)
  end
end
