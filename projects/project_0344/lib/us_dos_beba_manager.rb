require_relative 'us_dos_beba_scraper'
require_relative 'us_dos_beba_parser'
require_relative 'us_dos_beba_keeper'

class UsDosBebaManager < Hamster::Harvester
  def initialize
    super
    @keeper = UsDosBebaKeeper.new
    @run_id = @keeper.run_id
  end

  def download
    peon.throw_trash(10)
    logger.info 'The Trash was cleaned from files and catalogs older than 10 days'.green
    begin
      peon.move_all_to_trash
      logger.info 'The Store was cleaned from all files and catalogs'.green
    rescue => e
      logger.error "The Store not cleaned | #{e.message}".red
    end
    keeper.status = 'scraping'
    scraper = UsDosBebaScraper.new(keeper)
    scraper.start
    logger.info "##{Hamster.project_number} scraped #{scraper.count} news".green
  end

  def store
    keeper.status = 'parsing'
    parser        = UsDosBebaParser.new
    pages_of_list = peon.give_list(subfolder: "#{run_id}_pages_of_list")
    pages_of_list.each do |page|
      groups_of_start_data = parser.list(peon.give(file: page, subfolder: "#{run_id}_pages_of_list"))
      groups_of_start_data.each do |start_data|
        next if keeper.link_exists?(start_data[:link]) || !start_data[:link].match?(/state.gov/)

        md5 = MD5Hash.new(columns: %i[link])
        md5.generate({link: start_data[:link]})
        file_name  = md5.hash
        file       = peon.give(file: file_name, subfolder: "#{run_id}_article_pages")
        final_data = parser.get_from(file)
        keeper.save_to_db(start_data.merge(final_data))
      end
    end
    keeper.finish
    Hamster.logger.info "##{Hamster.project_number} parsed #{keeper.count} news".green
  end

  private

  attr_accessor :keeper, :run_id
end
