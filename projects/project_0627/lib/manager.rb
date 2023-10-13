require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @scraper = Scraper.new
    @keeper   = Keeper.new
    @parser   = Parser.new
    @subfolder_path = "#{@keeper.run_id}"
  end

  def download
    contributor_download
    expenditure_download
  end

  def store
    store_contribution
    store_expenditure
    keeper.finish
    tars_to_aws
  end

  private

  attr_accessor :keeper, :parser, :scraper, :subfolder_path

  def contributor_download
    all_dates.each_with_index do |interval, index|

      start_date, parsed_start_date, end_date, parsed_end_date = date_conversions(interval)
      response = scraper.contribution_landing
      page = parser.parse_html(response.body)

      cookie_value = fetch_cookie(response)
      event_validation, view_state, generator = parser.get_values(page)

      response_302 = scraper.contribution_302(cookie_value, event_validation, view_state, generator, start_date, end_date, parsed_end_date, parsed_start_date)
      load_response = scraper.contribution_load_page(cookie_value)
      wait_response = scraper.contribtions_wait_page(cookie_value)
      search_redirect = scraper.contribution_search_redirect(cookie_value)
      search_response = scraper.contribution_search(cookie_value)

      pp = parser.parse_html(search_response.body)
      event_validation, view_state, generator = parser.get_values(pp)

      download_response = scraper.contribution_download_file(cookie_value, event_validation, view_state, generator)
      save_csv(download_response.body, interval, 'contribution')
    end
  end

  def expenditure_download
    all_dates.each_with_index do |interval, index|

      start_date, parsed_start_date, end_date, parsed_end_date = date_conversions(interval)

      response     = scraper.expenditure_landing
      page         = parser.parse_html(response.body)
      cookie_value = fetch_cookie(response)
      event_validation, view_state, generator =  parser.get_values(page)

      response_302    = scraper.expenditure_302(cookie_value, event_validation, view_state, generator, start_date, end_date, parsed_end_date, parsed_start_date)
      load_response   = scraper.expenditure_load_page(cookie_value)
      wait_response   = scraper.expenditure_wait_page(cookie_value)
      search_redirect = scraper.expenditure_search_redirect(cookie_value)
      search_response = scraper.expenditure_search(cookie_value)

      pp = parser.parse_html(search_response.body)
      event_validation, view_state, generator = parser.get_values(pp)

      download_response = scraper.expenditure_download_file(cookie_value, event_validation, view_state, generator)
      save_csv(download_response.body, interval, 'expenditure')
    end
  end

  def store_contribution
    all_files  = Dir["#{storehouse}store/#{keeper.run_id}/contribution/*.csv"]
    all_files.each do |file|
      start_date, end_date = convert_date(file, 'contribution_')
      all_md5_hash = keeper.fetch_contribution_db_md5('contribution', 'contribution_date', start_date, end_date)
      hash_array, all_md5_hash = parser.get_contribution_data(file ,keeper.run_id, all_md5_hash)
      del_records = all_md5_hash.select{|k,v| v > 0}
      keeper.mark_ids_delete('contribution', del_records)
      keeper.insert_records('contribution', hash_array)
    end
  end

  def store_expenditure
    all_files  = Dir["#{storehouse}store/#{keeper.run_id}/expenditure/*.csv"]
    all_files.each do |file|
      start_date, end_date = convert_date(file, 'expenditure_')
      all_md5_hash = keeper.fetch_contribution_db_md5('expenditure', 'filing_date', start_date, end_date)
      hash_array, all_md5_hash = parser.get_expenditure_data(file ,keeper.run_id, all_md5_hash)
      del_records = all_md5_hash.select{|k,v| v > 0}
      keeper.mark_ids_delete('expenditure', del_records)
      keeper.insert_records('expenditure', hash_array)
    end
  end

  def convert_date(file, type)
    start_date = Date.parse(file.split('/').last.split('_to_').first.gsub("#{type}","").gsub('_','-'))
    end_date = Date.parse(file.split('/').last.split('_to_').last.gsub('.csv','').gsub('_','-'))
    [start_date, end_date]
  end

  def all_dates
    date_array = (Date.parse('2016/01/01')..(Date.today-1)).map(&:to_date)
    date_array.each_slice(30).to_a
  end

  def date_conversions(interval)
    start_date = "#{interval.first.month}/#{interval.first.day}/#{interval.first.year}"
    parsed_start_date = interval.first.to_s
    end_date   = "#{interval.last.month}/#{interval.last.day}/#{interval.last.year}"
    parsed_end_date = interval.last.to_s

    [start_date, parsed_start_date, end_date, parsed_end_date]
  end

  def fetch_cookie(response)
    return response.headers["set-cookie"]
    response.response.to_hash["set-cookie"].first
  end

  def clean_dir(path)
    FileUtils.rm_rf("#{path}/.", secure: true)
  end

  def directory_size(path)
    require 'find'
    size = 0
    Find.find(path) do |f|
      size += File.stat(f).size
    end
    size
  end

  def create_zip(file_name)
    obj = ZipFileGenerator.new("#{storehouse}store", "#{storehouse}trash/#{Hamster::project_number}_#{file_name}.zip")
    obj.write
  end

  def upload_zip(file_name)
    require "#{Dir.pwd}/lib/ashman/ashman"
    ashman = Hamster::Ashman.new({:aws_opts => {}, account: :hamster, bucket: 'hamster-storage1'})
    ashman.upload(key: "project_#{Hamster::project_number}_#{file_name}", file_path: "#{storehouse}trash/#{Hamster::project_number}_#{file_name}.zip")
    clean_dir("#{storehouse}trash")
  end

  def tars_to_aws
    file_name = "Run_Id_#{peon.list.min.to_i}_till_#{peon.list.max.to_i}"
    path = "#{storehouse}store"
    if (directory_size("#{path}").to_f / 1000000).round(2) > 1000 # Mb
      create_zip(file_name)
      clean_dir(path)
      upload_zip(file_name)
    end
  end

  def save_csv(response, interval, type)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}/#{type}"
    zip_storage_path = "#{storehouse}store/#{keeper.run_id}/#{type}/#{type}_#{interval.first.to_s.gsub("-","_")}_to_#{interval.last.to_s.gsub("-","_")}.csv"
    File.open(zip_storage_path, "wb") do |f|
      f.write(response)
    end
  end
end
