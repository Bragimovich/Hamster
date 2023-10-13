require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require 'zip'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper  = Keeper.new
    @parser  = Parser.new
    @scraper = Scraper.new
  end
  
  def download
    FileUtils.mkdir_p("#{storehouse}/store/#{keeper.run_id}")
    sub_folder = "#{keeper.run_id}"
    scraper.download(sub_folder)
  end
    
  def store
    count = 1
    hash_array = []
    file = "file.zip"
    file_path = "#{storehouse}store/#{keeper.run_id}/#{file}"
    Zip::File.open(file_path) do |zip_file|
      zip_file.each do |entry|
        content = ''
        entry.get_input_stream { |io| content = io.read }
        file_data = content.split("\r\n")
        file_data.each do |data|
          next unless data.include? "|"

          data_hash = parser.get_data(data ,keeper.run_id)

          data_hash.delete(:md5_hash)
          hash_array << data_hash
          if hash_array.count > 1999
            keeper.save_record(hash_array)
            hash_array = []
          end
        end
        keeper.save_record(hash_array) unless hash_array.empty?
      end
    end
    keeper.deletion_mark
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper

end
