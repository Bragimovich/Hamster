require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'
class Manager < Hamster::Harvester
  SLACK_ID = 'Halid Ibragimov'

  def download
    page    = 1
    scraper = Scraper.new
    keeper  = Keeper.new
    loop do
      puts page.to_s.green
      scrap  = scraper.get_json(page)
      break unless scrap

      parser = Parser.new
      data   = parser.parse(scrap)
      keeper.store_lawyers(data)
      page += 1
    end
    count = keeper.count
    keeper.finish
    message = "Scrap #542 was succes! --- #{count}"
    report_success(message)
  rescue => e
    Hamster.logger.error(e.full_message)
    report_success(message, :red)
  end

  private
  def report_success(message, color=:green)
    puts message.send(color)
    Hamster.report(to: SLACK_ID, message: message, use: :both)
  end
end
