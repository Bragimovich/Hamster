require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  MAIN_PAGE = "https://rp470541.doelegal.com/vwPublicSearch/Show-VwPublicSearch-Table.aspx"

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @subfolder = "Run_Id_#{@keeper.run_id}"
  end

  def run
    download unless keeper.download_status == 'finish'
    store
  end

  private

  def download
    scraper  = Scraper.new
    start_index = peon.list(subfolder: "Run_Id_#{keeper.run_id}").sort.last rescue 'a'
    ("#{start_index}"..'z').each do |letter|
      document       = scraper.fetch_outer_page
      cookie         = document.headers['set-cookie']
      get_body_data  = parser.get_body_data(document.body)
      view_generator = get_body_data[0]
      data           = scraper.fetch_first_page(cookie, get_body_data, letter)
      next_page      = 0
      while true
        next_page += 1
        save_file(data, next_page, letter)
        value_by_length = parser.pagination_body(data.body)
        all_values      = value_by_length.text.split('|')
        get_ind_value   = all_values.index "__VIEWSTATE"
        next_viewstate  = all_values[get_ind_value+1]
        data            = scraper.fetch_next_page(view_generator, next_viewstate, letter, next_page, cookie)
        current_page    = parser.get_page_value(data.body)
        break if current_page == next_page
      end
    end
    keeper.finish_download
  end

  def store
    count = 0
    letters = peon.list(subfolder: @subfolder).sort rescue []
    letters.each do |letter|
      data_array = []
      files = peon.give_list(subfolder: @subfolder +"/"+letter).sort
      files.each do |file|
        hash_array = parser.parse(peon.give(file:file, subfolder: @subfolder +"/"+letter), keeper.run_id)
        count = count + hash_array.count
        keeper.save_record(hash_array) unless hash_array.empty?
      end
    end
    keeper.mark_deleted
    keeper.finish
  end

  attr_accessor :keeper, :parser

  def save_file(response, file_name, sub_folder)
   peon.put content:response.body, file: file_name.to_s, subfolder: @subfolder+"/"+sub_folder
  end
end
