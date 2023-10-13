require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Scraper
  SUBFOLDER = "chicago_federation_musicians"

  def initialize
    super
    @parser = Parser.new
    @scraper = Scraper.new
    @keeper = Keeper.new
  end

  def download
    @scraper.scrape_data
  end

  def store
    run_id = @keeper.instance_variable_get('@run_id')
    @all_files = peon.give_list(subfolder: SUBFOLDER)
    @all_files.each do |file_name|
      file_content = peon.give(subfolder: SUBFOLDER,file: file_name)
      data = JSON.parse(file_content)
      @keeper.store_chicago_federation_musicians(data, run_id)
    end
    move_files_to_trash
    @keeper.finish
  end

  def move_files_to_trash
    time = Time.now.strftime("%Y_%m_%d")
    trash_folder = SUBFOLDER
    peon.list.each do |folder|
      peon.give_list(subfolder: folder).each do |file|
        peon.move(file: file, from: folder, to: trash_folder+"_"+time)
      end
    end
  end
end
