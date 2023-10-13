require_relative '../lib/keeper'
require_relative '../lib/parser'
require_relative '../lib/scraper'

class Manager < Hamster::Scraper
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def scrape
    download
    store
    @keeper.regenerate_and_flush
    @keeper.update_history
    @keeper.finish
  end

  def download
    page = 1
    loop do
      file_path = "#{store_file_path}/page_#{page}.dat"
      response = @scraper.search_result(page)
      inmate_ids = @parser.inmate_ids(response.body)

      break if inmate_ids.count.zero?

      store_data(file_path, inmate_ids)
      page += 1      
    end
  end

  def store
    files = Dir["#{store_file_path}/*"]
    files.each do |file_path|
      store_to_db(file_path)
    end
  end

  def clear
    @keeper.regenerate_and_flush
  end

  def clear_files
    files = Dir.glob(store_file_path + "/*")
    FileUtils.rm_rf files
  end

  private

  def store_to_db(file_path)
    file_data = File.read(file_path).split("\n")
    file_data.each do |data|
      data = eval(data)
      data_source_url = "#{Scraper::HOST}#{data[:href]}"
      response = @scraper.detail_page(data_source_url)

      next unless response

      begin
        hash_data = @parser.parse_detail_page(response.body, data_source_url, data)
        @keeper.store(hash_data)
      rescue => e
        logger.info "Raised error in store_to_db, url: #{data_source_url}, data: #{data}"
        logger.error e.full_message
        next
      end
    end
  end
  
  def store_data(file_path, data)
    File.open(file_path, 'w+') do |f|
      f.puts(data)
    end
  end

  def store_file_path
    store_path = "#{storehouse}store"
    FileUtils.mkdir_p(store_path)
    store_path
  end
end
