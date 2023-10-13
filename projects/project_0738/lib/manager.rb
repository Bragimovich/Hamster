# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'
require_relative 'connector'

class Manager < Hamster::Harvester
  THREADS_COUNT = 1
  MAX_RETRY     = 5
  def initialize(**params)
    super
    @keeper    = Keeper.new
    @parser    = Parser.new
    @semaphore = Mutex.new
  end

  def scrape(year = nil)
    years = year ? [year] : (2018..Date.today.year).to_a
    years.each do |year|
      Scraper.new(year).scrape
      store(year)
      Hamster.report(to: 'U04JS3K201J', message: "project_0738: Scraped all cases: #{year}")
    end
    logger.info('Scraped all case list')
  end

  def store(year = nil)
    years = year ? [year] : (2018..Date.today.year).to_a
    years.each do |year|
      stoer_by_year(year)
    end
  end

  def stoer_by_year(year)
    files = Dir["#{store_file_path(year)}/*"]
    threads = Array.new(THREADS_COUNT) do |thread_num| #4
      Thread.new do
        loop do
          file_path = nil
          @semaphore.synchronize {
            begin
              file_path = files.shift
            rescue StandardError => e
              file_path = nil
            end
          }

          break if file_path.nil?
          @connector = CaOcscCaseConnector.new(Scraper::START_PAGE)

          begin
            store_case_to_db(file_path)
          rescue StandardError => e
            logger.info(e.full_message)

            sleep(60)
          end
        end
      end
    end
    threads.each(&:join)
  end

  private

  def store_file_path(year)
    file_path = "#{storehouse}store/#{year}"
    FileUtils.mkdir_p(file_path)
    file_path
  end

  def store_case_to_db(file_path)
    file_data   = File.read(file_path).split
    added_count = 0
    logger.info("Started file: #{file_path}, count is #{file_data.length}")
    loop do
      retry_count = 0

      begin
        case_id = file_data.shift

        break if case_id.nil?
        if CaOcscCaseInfo.where(case_id: case_id).any?
          logger.info "This case_id(#{case_id}) is already exist"
          next
        end
        form_data  = {'caseNumber' => case_id, 'caseYear' => '', 'g-recaptcha-response' => '', 'action' => 'Search'}
        logger.info "Sent search request case_id is #{case_id}"
        case_page  = @connector.do_connect(Scraper::SEARCH_CASE_PAGE, method: :post, data: form_data)
        party_page = @connector.do_connect(Scraper::VIEW_PARTY_PAGE)
        hash_data  = @parser.process_page(case_page.body, case_id)
        hash_data[:party_info] = @parser.parse_case_party(party_page.body)
        @keeper.insert_record(hash_data)
        added_count += 1
      rescue StandardError => e
        logger.info("store_case_to_db --- retry: #{retry_count}")
        logger.info(e.full_message)

        file_data << case_id
        retry_count += 1

        raise e if retry_count > 3

        retry
      end
    end
    File.delete(file_path) if File.exist?(file_path)
    logger.info("Removed file #{file_path} and Added cases #{added_count}")
    added_count
  end
end
