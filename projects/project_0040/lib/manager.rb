require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  def initialize()
    super
    @keeper   = Keeper.new
    @parser   = Parser.new
    @db_processed_md5 = keeper.fetch_db_inserted_md5_hash
  end

  def file_download(cookie, page_no, scraper)
    response = scraper.get_data_request(cookie, page_no)
    save_file(response, "page_no_#{page_no}", "#{keeper.run_id}")
  end

  def download
    scraper = Scraper.new
    html = scraper.get_first_page
    cookie = html['set-cookie']
    get_total_pages = parser.get_total_pages(html)
    all_pages = (1..get_total_pages).map(&:to_i)
    downloaded_files = peon.give_list(subfolder: "#{keeper.run_id}")
    mutex = Mutex.new
    sliced_array = all_pages.each_slice(100).to_a
    sliced_array.each do |all_records|
      3.times.map {
        Thread.new(all_records) do |records|
          while page_no = mutex.synchronize { records.pop }
            next if downloaded_files.include? "page_no_#{page_no}.gz"
            begin
              file_download(cookie, page_no, scraper)
            rescue
              file_download(cookie, page_no, scraper)
            end
          end
        end
      }.each(&:join)
    end
  end

  def store
    all_files =  peon.give_list(subfolder: "#{keeper.run_id}").sort
    all_files.each do |file|
      response = peon.give(file: file, subfolder: "#{keeper.run_id}")
      page_no = file.scan(/\d+/).last.to_i
      records = parser.get_records(response)
      data_array=[]
      records.each do |record|
        record_hash, @db_processed_md5 = parser.scrape_data(record, page_no, keeper.run_id, @db_processed_md5)
        data_array << record_hash
      end
      keeper.save_record(data_array) unless data_array.empty?
    end
    keeper.deletion(@db_processed_md5)
    keeper.finish
  end
  private

  attr_accessor :parser, :keeper

  def save_file(html, name, folder)
    peon.put content: html, file: name, subfolder: folder
  end
end
