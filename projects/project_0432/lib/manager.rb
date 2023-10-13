require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper  = Keeper.new
    @parser  = Parser.new
  end

  def run
    (keeper.download_status == 'finish') ? store : download
  end

  def download(retries = 10)
    begin
      scraper = Scraper.new
      scraper.get_files(keeper.run_id)
      keeper.finish_download
    rescue StandardError => e
      raise if retries < 1
      download(retries - 1)
    end
  end

  def store
    all_files = peon.list(subfolder: "#{keeper.run_id}") rescue []
    all_files.each do |file|
      next if file.include? 'inspections'
      all_rows = parser.read_file("#{storehouse}store/#{keeper.run_id}/#{file}")
      hash_array, md5_array = [], []
      all_rows.each_with_index do |row, index_no|
        next if index_no == 0
        hash_array, md5_array = (file.include? 'inspections') ? parser.parse_inspections(row, keeper.run_id, md5_array, hash_array, index_no) : parser.parse_citations(row, keeper.run_id, md5_array, hash_array, index_no)
        if hash_array.count > 4999
          db_insert(file, hash_array, md5_array)
          hash_array, md5_array = [], []
        end
      end
      hash_array, md5_array = db_insert(file, hash_array, md5_array)
    end
    keeper.mark_deleted
    keeper.finish
  end

  private

  def db_insert(file, hash_array, md5_array)
    unless file == 'inspections.xlsx'
      keeper.save_records(hash_array, 'citations')
      keeper.update_touched_run_id(md5_array, 'citations')
    else
      keeper.save_records(hash_array, 'inspections')
      keeper.update_touched_run_id(md5_array, 'inspections')
    end
  end

  attr_accessor :keeper, :parser
end
