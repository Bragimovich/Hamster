require_relative 'scraper'
require_relative 'keeper'
require_relative 'parser'

class Manager < Hamster::Harvester
  SLACK_ID = 'Halid Ibragimov'
  URL      = 'https://www.courts.ri.gov/Courts/SupremeCourt/Pages/Opinions%20and%20Orders%20Issued%20in%20Supreme%20Court%20Cases.aspx'

  def initialize
    super
    @keeper  = Keeper.new
    @parser  = Parser.new
    @scraper = Scraper.new(url: URL)
    @run_id  = @keeper.run_id
  end
  def download
    links     = @scraper.scrape_links
    pdf_links = @scraper.scrape(links)
  end

  def store
    pages  = peon.give_list(subfolder: '1_pages')
    pages.each do |name|
      page = peon.give(subfolder: '1_pages', file: name)
      data = @parser.parse_site(page)
      data.each do |i|
        pdf_link = i[:link].gsub(' ', '%20')
        md5      = MD5Hash.new(columns:    [:url])
        md5.generate({url: pdf_link})
        name     = md5.hash

        pdf_path  = peon.move_and_unzip_temp(file: name, from: '1_pdfs')
        pdf       = @parser.parse_opinions(pdf_path)
        pdf.nil? ? next : @keeper.store(i, pdf, name)
      rescue => e
        Hamster.logger.error(e.full_message)
      end
    end
    @keeper.finish
    @keeper.delete_empty_rows
    message = "Scrape #592 was succes!"
    report_success(message)
  end

  private
  def report_success(message, color=:green)
    Hamster.report(to: SLACK_ID, message: message, use: :both)
  end
end
