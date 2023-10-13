require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
  end

  def run
    (keeper.download_status(keeper.run_id)[0].to_s == "true") ? store : download
  end

  private

  def download
    scraper = Scraper.new(keeper)
    already_fetched = keeper.get_deceased_records
    ('A'..'Z').each do |letter|
      subfolder_path = create_subfolder(letter)
      downloaded_files = peon.give_list(subfolder:subfolder_path)
      page = 1
      while true
        html = scraper.scrape_new_data(letter, page, subfolder_path)
        save_file(html, "page_#{page}", subfolder_path)
        records = parser.get_records(html)
        break if records.count == 0
        records.each do |record|
          file_name = record["id"].to_s
          url = "https://www.padisciplinaryboard.org/for-the-public/find-attorney/attorney-detail/#{record["id"]}"
          next if (already_fetched.include? url) || (downloaded_files.include? (file_name + ".gz"))
          body = scraper.save_inner_record(file_name, subfolder_path)
          save_file(body, file_name, subfolder_path)
        end
        page += 1
      end
    end
    keeper.mark_download_status(keeper.run_id)
    store if (keeper.download_status(keeper.run_id)[0].to_s == "true")
  end

  def store
    already_fetched = keeper.get_deceased_records
    letter_folders = (peon.list(subfolder: "#{keeper.run_id}").select{|s| s.include? 'letter_'}).sort
    letter_folders.each do |letter_folder|
      data_array = []
      delete_record = []
      subfolder = "#{keeper.run_id}/#{letter_folder}"
      outer_page_files = get_outer_page_files(subfolder)
      outer_page_files.each do |file|
        outer_page = peon.give(subfolder: subfolder, file: file)
        outer_content = parser.get_records(outer_page)
        outer_content.each do |record_json|
          file_name = record_json["id"].to_s
          url = "https://www.padisciplinaryboard.org/for-the-public/find-attorney/attorney-detail/#{record_json["id"]}"
          next if already_fetched.include? url
          body = peon.give(file:file_name, subfolder:subfolder) rescue nil
          next if body.nil?
          data_hash = parser.prepare_hash(body, record_json, keeper.run_id)
          delete_record << data_hash["md5_hash"]
          data_array << data_hash
        end
      end
      keeper.save_record(data_array)
      keeper.update_touched_run_id(delete_record)
    end
    keeper.mark_deleted
    keeper.finish
  end

  attr_accessor :keeper, :parser

  def get_outer_page_files(subfolder)
    peon.give_list(subfolder: subfolder).select{|file| file.include? 'page_'}
  end

  def save_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  def create_subfolder(letter)
    data_set_path = "#{storehouse}store/#{keeper.run_id}"
    FileUtils.mkdir(data_set_path) unless Dir.exist?(data_set_path)
    data_set_path = "#{data_set_path}/letter_#{letter}"
    FileUtils.mkdir(data_set_path) unless Dir.exist?(data_set_path)
    data_set_path.split("store/").last
  end
end
