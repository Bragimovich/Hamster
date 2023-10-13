require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = @keeper.run_id.to_s
  end

  def run
    download
    store
    FileUtils.rm_rf Dir.glob("#{storehouse}/store/#{run_id}*")
  end

  def download
    name_flag = true
    for name_search in (0..1) do
      name_search == 1 ? name_flag = false : name_flag
      outer_folder = name_search == 0 ? 'first_name' : 'last_name'
      for search_key in ('a'..'z') do
        already_downloaded_files = get_already_downloaded_files rescue []
        main_page = scraper.main_page_request
        cookie = main_page.headers['set-cookie']
        count = 0
        start = 0
        while true
          inner_page = scraper.inner_page_request(cookie, name_flag, search_key, start)
          ids, total_pages = parser.get_ids(inner_page.body)
          break if count > total_pages
          ids.each do |id|
            next if already_downloaded_files.include? "#{id}.gz"
            data_page = scraper.get_data_page(id, cookie)
            save_html_file(data_page.body, id, "#{run_id}/#{outer_folder}/#{search_key}/#{count}")
          end
          start = start + 50
          count = count + 1
        end
      end
    end
  end

  def store
    names_folders = peon.list(subfolder: run_id)
    names_folders.each do |name_folder|
      latters_folders = peon.list(subfolder: "#{run_id}/#{name_folder}").sort
      latters_folders.each do |key|
        pages_folders = peon.list(subfolder: "#{run_id}/#{name_folder}/#{key}").sort
        pages_folders.each do |data_folder|
          files = peon.give_list(subfolder: "#{run_id}/#{name_folder}/#{key}/#{data_folder}")
          files.each do |file|
            data = peon.give(file: file, subfolder:  "#{run_id}/#{name_folder}/#{key}/#{data_folder}")
            data_array = parser.get_data(data, run_id)
            keeper.insert_data(data_array, run_id)
          end
        end
      end
    end
    keeper.mark_delete
    keeper.finish
  end

  private

  def get_already_downloaded_files
    all_files = []
    names_folders = peon.list(subfolder: run_id)
    names_folders.each do |name_folder|
      latters_folders = peon.list(subfolder: "#{run_id}/#{name_folder}")
      latters_folders.each do |key|
        pages_folders = peon.list(subfolder: "#{run_id}/#{name_folder}/#{key}")
        pages_folders.each do |data_folder|
          files = peon.give_list(subfolder: "#{run_id}/#{name_folder}/#{key}/#{data_folder}")
          all_files = all_files + files
        end
      end
    end
    all_files
  end

  def save_html_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  attr_accessor :keeper, :parser, :scraper, :run_id
end
