# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize
    super
    @parser = MilwaukeeCountyParser.new
    @current_date = Date.today
    @keeper = Keeper.new
    @last_scrape_status = "#{Date.today}"
    @last_scrape_date = "#{@last_scrape_status}"
    @next_scrape_status = "#{Date.today.next_day}"
    @next_scrape_date = "#{@next_scrape_status}"
  end

  def download
    scraper = Scraper.new
    5.times do
      result_json = scraper.get_json_result(@current_date)
      next if result_json.body.include? "Could not access any server machines"
      save_page(result_json,@current_date, "Milwaukee_County")
      break
    end
  end

  def store
    pages = peon.give_list(subfolder: "Milwaukee_County")
    error_count = 0
    result_json = peon.give(file:pages.max, subfolder: "Milwaukee_County")
    hash_array = []
    results = @parser.convert_json_body(result_json)
    results["features"].each do |final|
      data_hash = {}
      begin
        data_hash = @parser.parse_json(final)
      rescue Exception => e
        error_count +=1
        raise e.full_message if error_count > 10
        p e.full_message
        Hamster.report(to: 'Muhammad Adeel Anwar', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
      next if (data_hash.empty?)
      data_hash[:last_scrape_date] = @last_scrape_date
      data_hash[:next_scrape_date] = @next_scrape_date
      hash_array << data_hash
    end
    @keeper.insertion(hash_array)
    @keeper.mark_deleted
  end

  private

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end
end
