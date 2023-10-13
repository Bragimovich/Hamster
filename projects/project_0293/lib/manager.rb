require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'
require_relative '../lib/zip_generator'
require 'zip'

class Manager <  Hamster::Harvester
  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def run_script
    (keeper.download_status == 'finish') ? store : download
  end

  def download
    scraper = Scraper.new
    offset = 0
    page = 1
    while true
      response = scraper.call_api(offset)
      body = parser.json_parse(response.body)
      break if body.empty?
      save_file("#{keeper.run_id}", response.body, "file_#{page}.json")
      page += 1
      offset += 50000
    end
    keeper.finish_download
    store if (keeper.download_status == 'finish')
  end

  def store
    all_csv = peon.give_list(subfolder: "#{keeper.run_id}")
    all_csv.each do |file|
      file_data = peon.give(subfolder: "#{keeper.run_id}", file: file)
      csv_data, md5_hash_array = parser.csv_data(file_data, keeper.run_id)
      keeper.insert_records(csv_data)
      keeper.update_touch_run_id(md5_hash_array)
      keeper.del_using_touch_id
    end
    if (keeper.download_status == 'finish')
      keeper.finish
      tars_to_aws
    end
  end

  private
  attr_accessor :keeper, :parser

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
  end

  def tars_to_aws
    file_name = "Run_Id_#{peon.list.min.to_i}_till_#{peon.list.max.to_i}"
    path = "#{storehouse}store"
    if (directory_size("#{path}").to_f / 1000000).round(2) > 1000 # Mb
      create_zip(file_name)
      clean_dir(path)
      upload_zip(file_name)
    end
    clean_dir("#{storehouse}trash")
  end

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end
end
