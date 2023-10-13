require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
  end

  def download
    iterator = 1
    while true
      page = scraper.connect_page(iterator)
      is_next = parser.is_next_page(page)
      save_page(page,"#{iterator}","#{keeper.run_id}")
      break if is_next == false
      iterator += 1
    end
    keeper.finish_download
  end

  def store
    download_status = keeper.download_status
    message = "Downloader is Still running for 253 project"
    if download_status == 'processing'
      Hamster.report(to: 'Aqeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{message}", use: :slack)
      return
    end
    
    get_salary_data = []
    stored_files = peon.give_list(subfolder: "#{keeper.run_id}")
    stored_files.each do |file|
      outer_page = peon.give(subfolder: "#{keeper.run_id}", file: "#{file}")
      get_salary_data = (get_salary_data << parser.get_salary_data(outer_page, keeper.run_id)).flatten
      if get_salary_data.count >= 5000
        md5_hashes = get_salary_data.map  { |e| e.delete(:md5_hash) }
        keeper.insert_records(get_salary_data)
        keeper.update_touch_run_id(md5_hashes)
        get_salary_data = []
      end
    end
    md5_hashes = get_salary_data.map  { |e| e.delete(:md5_hash) }
    keeper.insert_records(get_salary_data) unless get_salary_data.empty?
    keeper.update_touch_run_id(md5_hashes)
    keeper.delete_using_touch_id
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser , :scraper

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end

end
