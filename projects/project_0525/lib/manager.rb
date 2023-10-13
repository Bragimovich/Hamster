require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @sub_folder = "Run_ID_#{@keeper.run_id}"
  end

  def download(retries = 10)
    begin
      starting_index = resuming_download
      scraper = Scraper.new
      generate_letters[starting_index..-1].each_with_index do |letter, letter_index|
        puts "processing Letter --->>> #{letter}"
        response = scraper.scrape(letter)
        save_file(response, letter.to_s, sub_folder)
      end
    rescue StandardError => e
      raise if retries <= 1
      download(retries - 1)
    end
  end

  def store
    already_inserted_md5_hashes = keeper.fetch_already_inserted_md5
    alreay_downloaded_files = peon.give_list(subfolder: sub_folder).sort
    alreay_downloaded_files.each do |file_name|
      run_id_update_array = []
      file = peon.give(file: file_name, subfolder: sub_folder)
      data_array, already_inserted_md5_hashes, run_id_update_array = parser.parser(file, file_name, keeper.run_id, already_inserted_md5_hashes, run_id_update_array)
      keeper.update_touch_run_id(run_id_update_array)
      keeper.save_records(data_array)
    end
    keeper.mark_deleted
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :sub_folder

  def generate_letters
    ('a'..'z').map(&:to_s)
  end

  def resuming_download
    max_file = peon.give_list(subfolder: sub_folder).sort.max rescue nil
    return 0 if max_file.nil?
    (generate_letters.index max_file.gsub(".gz",""))+1
  end

  def save_file(html, file_name, sub_folder)
    peon.put content: html, file: file_name, subfolder: sub_folder
  end
end
