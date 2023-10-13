require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester
  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download 
    scraper = Scraper.new
    offset = 0
    page = 1
    while true
      response = scraper.call_api(offset)
      break if JSON.parse(response.body).empty?
      save_file("#{keeper.run_id}", response.body, "file_#{page}.json")
      page += 1
      offset += 20000
    end
  end

  def store
    all_csv = peon.give_list(subfolder: "#{keeper.run_id}")
    all_csv.each do |file|
      file_data = peon.give(subfolder: "#{keeper.run_id}", file: file)
      csv_data = parser.csv_data(file_data,keeper.run_id)
      keeper.insert_records(csv_data)
    end
    keeper.finish
  end

  private 

  attr_accessor :keeper, :parser 

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end
end
