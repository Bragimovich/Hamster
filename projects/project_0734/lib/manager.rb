require_relative 'constants'
require_relative 'parser'
require_relative 'keeper'
require_relative 'scraper'

class Manager < Hamster::Scraper

  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download
    @logger.info "Starting Downloading..."
    
    link = "#{BASE_URL}/salaries/"
    res, _ = @scraper.get_request(link)
    save_file(res.body, MAIN_FILE_NAME)
    links = @parser.get_links(res.body)

    salaries_storage_path = "#{PROJECT_STORAGE_DIR}/Salaries.xlsx"
    earnings_storage_path = "#{PROJECT_STORAGE_DIR}/Earnings.xlsx"
    
    @scraper.get_requested_file(links[:salaries_link],salaries_storage_path)
    @scraper.get_requested_file(links[:earnings_link],earnings_storage_path)

    @logger.info "Finished Downloading..."
  end

  def store
    begin
      process_each_file
    rescue Exception => e
      @logger.error e.full_message
    end
  end

  private

  def process_each_file
    @logger.info "Processing started..."

    salaries_storage_path = "#{PROJECT_STORAGE_DIR}/Salaries.xlsx"
    earnings_storage_path = "#{PROJECT_STORAGE_DIR}/Earnings.xlsx"

    salary_records = @parser.salaries_file_parser(salaries_storage_path)
    salary_records.each{|record|
      @keeper.store_salary(record)
    }

    earning_records = @parser.earnings_file_parser(earnings_storage_path)
    earning_records.each{|record|
      @keeper.store_earning(record)
    }

    @logger.info "Processing ended..."
    @keeper.finish
  end

  def read_file(file_path)
    file = File.open(file_path).read
    file
  end

  def save_file(content, file_name)
    peon.put content: content, file: file_name
  end

end