require_relative '../lib/us_tax_exem_org_scraper'
require_relative '../lib/us_tax_exem_org_parser'
require_relative '../lib/us_tax_exem_org_keeper'
class USTaxExemOrgManager < Hamster::Harvester

  TASK_NAME = "#417 US Tax Exempt Organizations: Non-Profit organizations' XML parsing".freeze
  SLACK_ID  = 'Eldar Eminov'.freeze
  HOST      = 'https://nonprofitlight.com'.freeze

  def initialize(**params)
    super
    @keeper = USTaxExemOrgKeeper.new
  end

  def download
    message = '#417 Start scraping'
    report_success(message)
    scraper = USTaxExemOrgScraper.new(keeper)
    scraper.scrape_org
    message = '#417 End scraping'
    report_success(message)
  rescue StandardError => e
    puts "#{e} | #{e.full_message}"
    Hamster.report(to: SLACK_ID, message: e, use: :both)
  end

  def store
    message = '#417 Start scraping'
    report_success(message)
    run_id = keeper.run_id
    orgs   = peon.give_list(subfolder: "#{run_id}_xml")
    orgs.each_with_index do |name, idx|
      puts "Page #{idx}".green
      xml     = peon.give(file: name, subfolder: "#{run_id}_xml")
      urls    = peon.give(file: name, subfolder: "#{run_id}_url")
      xml_url = urls.match(/.+/).to_s
      web_url = urls.match(/\n.+$/m).to_s.lstrip
      parser  = USTaxExemOrgParser.new(xml: xml)
      org     = parser.parse_xml
      org.merge!({ web_url: web_url, data_source_url: xml_url })
      keeper.save_org(org)
    end
    count   = keeper.count
    message = "#417 End parsing,  pages: #{count}"
    keeper.finish
    report_success(message)
  rescue StandardError => e
    puts "#{e} | #{e.full_message}"
    Hamster.report(to: SLACK_ID, message: e, use: :both)
  end

  private

  attr_reader :keeper

  def report_success(message)
    puts message.green
    Hamster.report(to: SLACK_ID, message: message, use: :both)
  end
end
