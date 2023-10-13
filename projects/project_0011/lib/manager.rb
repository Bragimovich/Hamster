require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = "#{@keeper.run_id}"
  end

  def run
    (keeper.download_status == "finish") ? store : download
  end

  private

  def download
    scraper = Scraper.new
    main_page = scraper.fetch_main_page
    last_scrape_date = keeper.fetch_latest_scrape_date
    get_current_date = parser.get_current_date(main_page)
    downloaded_files = resuming_function
    remove_last_file(downloaded_files) unless downloaded_files.empty?
    downloaded_files = downloaded_files[0..-2] unless downloaded_files.empty?
    if last_scrape_date < get_current_date
      save_page(main_page, "main_page", "#{run_id}")
      all_links = parser.get_csv_links(main_page)
      all_names = parser.get_csv_names(main_page)
      all_links.zip(all_names).each do |link, name|
        next if downloaded_files.include?(name)
        scraper.download_file(storehouse, run_id, link)
      end
      keeper.finish_download
      store
    end
  end

  def store
    file_names = keeper.db_inserted_files
    all_folders = peon.list(subfolder: "#{run_id}").reject{|a| a.include? "main_page"}
    all_folders.each do |file|
      file_name = file.gsub(".csv", "")
      next if file_names.include?  file_name
      file = Dir["#{storehouse}store/#{run_id}/#{file}"].first
      parse_and_save_data(file, file_name)
    end
    if keeper.download_status == "finish"
      keeper.mark_delete
      keeper.finish
      tars_to_aws
    end
  end

  attr_accessor :parser, :scraper, :keeper, :run_id

  def resuming_function
    peon.list(subfolder: "#{run_id}").reject{|a| a.include? "main_page"}.sort rescue []
  end

  def remove_last_file(downloaded_files)
    FileUtils.rm("#{storehouse}store/#{run_id}/#{downloaded_files[-1]}")
  end

  def tars_to_aws
    file_name = "Run_Id_#{run_id}"
    path = "#{storehouse}store"
    create_zip(file_name)
    clean_dir(path)
    upload_zip(file_name)
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


  def parse_and_save_data(file, csv_file_name)
    csv_array, headers, loan_numbers = [], [], []
    CSV.open(file, 'r') do |csv|
      csv.each_with_index do |row, index|
        if index == 0
          headers = row
          next
        end
        csv_hash = headers.zip(row).to_h
        loan_numbers << csv_hash["LoanNumber"]
        csv_array << parser.create_hash(csv_hash, run_id, csv_file_name)
        if csv_array.count % 5000 == 0
          keeper.insert_records(csv_array)
          keeper.update_touched_run_id(loan_numbers)
          csv_array, loan_numbers = [], []
        end
      end
    end
    unless csv_array.empty?
      keeper.insert_records(csv_array)
      keeper.update_touched_run_id(loan_numbers)
    end
  end

  def save_page(html, file_name, sub_folder)
    peon.put(content: html.body, file: file_name, subfolder: sub_folder)
  end
end
