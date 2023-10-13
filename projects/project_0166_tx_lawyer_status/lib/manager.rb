require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper     = Keeper.new
    @parser     = Parser.new
    @already_inserted_links   = @keeper.fetch_db_inserted_links
  end

  def download
    scraper = Scraper.new
    start_index = start_index = peon.list(subfolder: "RunId_#{keeper.run_id}").sort.last rescue nil
    start_index = 'aaa' if start_index.nil?
    (start_index..'zzz').each do |name|
      already_downloaded_files = get_already_downloaded_files
      response    = scraper.connect_to_form_data(name)
      total_pages = parser.get_last_page(response)-1 rescue 0
      (0..total_pages).each do |page|
        unless page == 0
          page     = (page*25) + 1
          response = scraper.connect_to_form_data(name, page)
        else
          response = scraper.connect_to_form_data(name)
        end
        links = parser.get_links(response)
        next if links.empty?

        links = links.reject { |e| already_downloaded_files.include? e.split('=').last + '.gz'}
        links.each do |link|
          folder   = peon.list(subfolder: "RunId_#{keeper.run_id}/#{name}").map{|a| a.split("_").last.to_i}.sort.last rescue []
          page_num = (folder == []) ? page : folder

          file_name  = link.split('=').last
          inner_page = scraper.download_inner_pages(link)
          save_file(inner_page.body, file_name, "RunId_#{keeper.run_id}/#{name}")
        end
      end
    end
    keeper.finish_download
  end

  def store
    folders = peon.list(subfolder: "RunId_#{keeper.run_id}") rescue []
    md5_hash_array    = []
    data_array        = []
    folders.each do |folder|
      state_pages_folder = peon.list(subfolder: "RunId_#{keeper.run_id}/#{folder}")
      data_array = get_data(state_pages_folder, folder)
      md5_hash_array = data_array.map { |e| e[:md5_hash]}
      md5_hash_array.each_slice(2000){|data| keeper.update_touch_run_id(data)}
      data_array.each_slice(2000){|data| keeper.save_record(data)}
    end
    if keeper.download_status == "finish"
      keeper.del_using_touch_id
      keeper.finish
    end
  end

  private

  attr_accessor :keeper, :parser, :already_inserted_links

  def get_already_downloaded_files
    files = []
    folders = peon.list(subfolder: "RunId_#{keeper.run_id}") rescue []
    folders.each do |folder|
      all_files = peon.give_list(subfolder: "RunId_#{keeper.run_id}/#{folder}") rescue []
      files = files + all_files
    end
    files
  end

  def get_data(all_files, key)
    data_array = []
    all_files.each do |file|
      link = "https://www.texasbar.com/AM/Template.cfm?Section=Find_A_Lawyer&template=/Customsource/MemberDirectory/MemberDirectoryDetail.cfm&ContactID=#{file.gsub('.gz', '')}"
      link_data  = peon.give(subfolder: "RunId_#{keeper.run_id}/#{key}", file: file)
      data_array << parser.parser(link_data, link, "#{keeper.run_id}")
    end
    data_array
  end

  def save_file(html, file_name, sub_folder)
    peon.put content: html, file: file_name, subfolder: sub_folder
  end
end
