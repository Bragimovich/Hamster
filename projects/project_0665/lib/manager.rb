require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(**params)
    super
    @parser      = Parser.new
    @keeper      = Keeper.new
  end

  def run_script
    (keeper.download_status == "finish") ? store : download
  end

  def download
    scraper = Scraper.new
    counter = resume_point
    while true
      response = requesting(scraper, counter)
      break if parser.parse_json(response.body).empty?
      save_file(response.body, "file_#{counter}", "#{keeper.run_id}")
      counter += 10000
    end
    keeper.finish_download
    store
  end

  def store
    files = peon.list(subfolder: "#{keeper.run_id}").sort
    files.each do |file|
      content = peon.give(file: file, subfolder: "#{keeper.run_id}")
      records_array = parser.get_data(content, keeper.run_id)
      records_md5_hashes = records_array.map { |data| data[:md5_hash] }
      keeper.save_records(records_array)
      keeper.update_touch_run_id(records_md5_hashes)
    end
    if (keeper.download_status == "finish")
      keeper.delete_using_touch_id
      keeper.finish
      clean_dir
    end
  end

  attr_accessor :parser, :keeper
  private

  def clean_dir
    FileUtils.rm_rf("#{storehouse}store/.", secure: true)
  end

  def requesting(scraper, counter)
    wrong_counter = 1
    while true
      break if wrong_counter == 8
      response = scraper.fetch_data(counter)
      break if response.status == 200
      wrong_counter += 1
    end
    response
  end

  def save_file(body, file_name, sub_folder)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end

  def resume_point
    max_counter = peon.list(subfolder: "#{keeper.run_id}").map{|e| e.split('_').last.gsub('.gz','').to_i}.max rescue nil
    return 0 if max_counter.nil?
    max_counter
  end
end
