require_relative '../lib/irs_non_profit_scraper'
require_relative '../lib/irs_non_profit_parser'
require_relative '../lib/irs_non_profit_keeper'

class IrsNonProfitManager < Hamster::Harvester
  SLACK_ID = 'Eldar Eminov'.freeze

  def initialize
    super
    @keeper = IrsNonProfitKeeper.new
    @debug  = commands[:debug]
    @forms  = commands[:forms]
    @org    = commands[:org]
    @all    = true unless @forms || @org
  end

  def download
    if keeper.status == 'finish'
      peon.move_all_to_trash
      notify 'The Store was cleaned from all files and catalogs'
    end
    keeper.status = 'scraping'
    peon.throw_trash(30)
    notify 'The Trash was cleaned from files and catalogs older than 30 days'
    scraper = IrsNonProfitScraper.new(@keeper)
    if @forms || @all
      scraper.scrape_forms
      successful_message "Success scraped forms"
    elsif @org || @all
      scraper.scrape_org
      successful_message "Success scraped #{scraper.count} orgs"
    end
  end

  def store
    keeper.status = 'parsing'
    run_id = keeper.run_id
    if @all || @forms
      names = peon.give_list(subfolder: "#{run_id}_forms")
      names.each do |name|
        keeper.count = 0
        new_date = name.match(/\d{4}_\d{2}_\d{2}/).to_s.gsub('_', '-').to_date
        if name.match?(/index.csv/)
          next if name.match?(/txt.gz$/)

          csv      = peon.give(file: name, subfolder: "#{run_id}_forms")
          date_raw = name.match(/\d{4}_\d{2}_\d{2}_/).to_s
          link     = 'https://www.irs.gov/pub/irs-tege/' + name.sub(/\.gz/, '').sub(date_raw, '')
          keeper.update_form_990s(csv, link)
          keeper.update_last_scrape_date('990s', new_date)
          successful_message "Success parsed and saved in db #{keeper.count} ein"
          next
        end

        path = peon.copy_and_unzip_temp(file: name, from: "#{run_id}_forms")
        name = name.match(/pub_78|990_n|auto_rev_list/).to_s
        save_form(path, name, new_date) if name.present?
      end
    end

    if @all || @org
      keeper.count = 0
      names_orgs = peon.give_list(subfolder: "#{run_id}_orgs")
      names_orgs.each_with_index do |file_name, idx|
        logger.debug "#{idx} --- #{file_name}"
        page   = peon.give(file: file_name, subfolder: "#{run_id}_orgs")
        parser = IrsNonProfitParser.new(json: page)
        orgs   = parser.parse_orgs
        keeper.save_org(orgs)
      end
      successful_message "Success parsed and saved the orgs in db #{keeper.count} ein"
    end

    peon.throw_temps
    notify 'Throw temps'
    keeper.finish
  end

  private

  attr_reader :keeper

  def save_form(path, name, new_date)
    method_ = "update_#{name}"
    keeper.send(method_, path)
    keeper.update_last_scrape_date(name, new_date)
    successful_message "Success parsed and saved the #{name} in db #{keeper.count} ein"
  end

  def successful_message(message)
    notify message
    Hamster.report(to: SLACK_ID, message: "##{Hamster.project_number} | #{message}", use: :both)
  end

  def notify(message, color=:green)
    method_ = @debug ? :debug : :info
    message = color.nil? ? message : message.send(color)
    Hamster.logger.send(method_, message)
  end
end
