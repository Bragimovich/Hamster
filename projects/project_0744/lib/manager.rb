# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @scraper = Scraper.new
  end

  def download
    main_response = @scraper.get_main_response
    cookie_value = main_response.headers['set-cookie']
    event_val,view_state,view_state_gen,years = @parser.get_event_values_and_years(main_response.body)
    years.each do |year|
      post_response = @scraper.get_post_response(cookie_value,event_val,view_state,view_state_gen,year)
      saving_file(post_response.body,"#{year}","#{@keeper.run_id}",'csv')
    end
  end

  def store
    files = Dir["#{storehouse}store/#{@keeper.run_id}/*.csv"]
    files.each do |file|
      data_array,md5_array = @parser.parse_data(file,@keeper.run_id)
      @keeper.insert_records(data_array)
      @keeper.update_touch_run_id(md5_array)
    end
    @keeper.mark_delete
    @keeper.finish
    FileUtils.rm_rf("#{storehouse}store/#{@keeper.run_id}")
  end

  private

  def saving_file(content,file_name,path,type)
    FileUtils.mkdir_p "#{storehouse}store/#{path}"
    file_storage_path = "#{storehouse}store/#{path}/#{file_name}.#{type}"
    File.open(file_storage_path, "wb") do |f|
      f.write(content)
    end
  end

end
