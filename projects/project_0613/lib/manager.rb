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
    page = 1
    while true
      main_page_request = scraper.main_page(page)
      main_page_body = parser.main_page_body(main_page_request)
      save_file("#{keeper.run_id}", main_page_request.body, "mi_salaries_page_#{page}")
      next_link = parser.next_page(main_page_body)
      page += 1 if next_link == true
      break if next_link == false
    end
    keeper.download_finished
  end

  def store
    if keeper.download_status == "finish"
      dz_files = peon.give_list(subfolder: "#{keeper.run_id}")
      dz_files.each do |file|
        md5_hash_array = []
        each_page_content = peon.give(subfolder: "#{keeper.run_id}", file: file)
        government_salaries = parser.michigan_government_salaries(each_page_content, keeper.run_id, file)
        government_salaries.each do |each_hash|
          md5_hash_array << each_hash[:md5_hash]
        end
        keeper.mi_salaries(government_salaries) unless government_salaries.empty? || government_salaries.nil?
        keeper.update_touched_runId(md5_hash_array) unless md5_hash_array.empty? || md5_hash_array.nil?
      end
      keeper.mark_deleted
      keeper.finish
    end
  end

  private
  attr_accessor :keeper, :parser, :scraper

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end
end
