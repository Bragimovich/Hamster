require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Scraper
  PR_FOLDER = "scrape_pr"
  CATEGORY_FOLDER = "scrape_catagory"
  SUB_CATEGORY_FOLDER = "scrape_sub_catagory"
  STORE_FOLDERS = ['scrape_pr', 'scrape_catagory', 'scrape_sub_catagory']
  
  def initialize
    super
    @parser = Parser.new
    @scraper = Scraper.new
    @keeper = Keeper.new
  end

  def download
    @scraper.scrape_pr
    @scraper.scrape_categories_with_links
    @scraper.scrape_subcategories_and_links
  end

  def store
    STORE_FOLDERS.each do |sub_folder|
      store_data(sub_folder)
    end
    move_files_to_trash(STORE_FOLDERS)
  end

  def store_data(sub_folder)
    @all_files = peon.give_list(subfolder: sub_folder)
    @all_files.each do |file_name|
      file_content = peon.give(subfolder: sub_folder,file: file_name)
      data = JSON.parse(file_content)
      case sub_folder
      when "scrape_pr"
        @keeper.store_pr_data(data)
      when "scrape_catagory"
        @keeper.store_catagory_data(data)
      when "scrape_sub_catagory"
        @keeper.store_sub_catagory_data(data)
      end
    end
  end

  def move_files_to_trash(store_folders)  
    time = Time.now.strftime("%Y_%m_%d")
    trash_folder = store_folders
    peon.list.each do |folder|
      peon.give_list(subfolder: folder).each do |file|
        peon.move(file: file, from: folder, to: folder+"_"+time)
      end
    end
  end
end
