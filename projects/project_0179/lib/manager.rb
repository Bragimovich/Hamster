# frozen_string_literal: true

require_relative 'ac_keeper'
require_relative 'dc_keeper'
require_relative 'parser'
require_relative 'ac_scraper'
require_relative 'dc_scraper'
require_relative 'connector'

class Manager < Hamster::Harvester
  THREADS_COUNT = 8
  MAX_RETRY     = 5
  attr_reader :baned_proxies, :paid_proxies
  def initialize(**params)
    super
    @court_type    = params[:court_type]
    @keeper        = @court_type == :ac ? AcKeeper.new : DcKeeper.new
    @parser        = Parser.new
    @semaphore     = Mutex.new
    @baned_proxies = {}
    @using_proxies = {}
    @paid_proxies  = PaidProxy.where(is_socks5: 1)

    log_dir        = "#{storehouse}log"
    log_file       = "#{log_dir}/project_0179_#{@court_type}.log"
    FileUtils.mkdir_p(log_dir)
    File.open(log_file, 'a') { |file| file.puts Time.now.to_s }
    @logger        = Logger.new(log_file, Logger::INFO)
  end

  def scrape
    name_array = ('AA'..'ZZ').to_a
    threads = Array.new(1) do |thread_num| #4
      Thread.new do
        loop do
          name = nil
          @semaphore.synchronize {
            begin
              name = name_array.shift
            rescue StandardError => e
              name = nil
            end
          }

          break if name.nil?
          log_message = "----Starting: #{thread_num}------pick: #{name}---#{@court_type}"
          @logger.info(log_message)
          Hamster.report(to: 'U04JS3K201J', message: "project_0179: #{log_message}")
          begin
            scraper =
              if @court_type == :ac
                AcScraper.new(name[0], name[1], self)             
              else
                DcScraper.new(name[0], name[1], self)
              end
            scraper.scrape()
            @using_proxies.delete(scraper.proxy)
            
            log_message = "----End: #{thread_num}------pick: #{name}---#{@court_type}"
            @logger.info(log_message)
            Hamster.report(to: 'U04JS3K201J', message: "project_0179: #{log_message}")
          rescue ActiveRecord::ConnectionTimeoutError
            sleep(5)
            retry
          rescue StandardError => e
            log_message = "----Error: #{thread_num}------pick: #{name}---#{@court_type}"
            @logger.info(log_message)
            @logger.info(e.full_message)
            Hamster.report(to: 'U04JS3K201J', message: "project_0179: #{log_message}")
            puts e.full_message

            @semaphore.synchronize {
              name_array << name
            }
            puts "******sleeping thread #{thread_num}****pick: #{name}---#{@court_type}**"
            sleep(3600)
          end
        end
      end
    end

    threads.each(&:join)
    Hamster.report(to: 'U04JS3K201J', message: "project_0179: #{@court_type} Scrape Done!")
    store()
  end

  def store
    files = Dir["#{storehouse}/store/#{@court_type}/*"]
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
          log_message = "----Starting: #{thread_num}------pick: #{file_path}"
          @logger.info(log_message)
          Hamster.report(to: 'U04JS3K201J', message: "project_0179: #{log_message}")
          begin
            parse_and_store(file_path)
            log_message = "----End: #{thread_num}------pick: #{file_path}"
            @logger.info(log_message)
            Hamster.report(to: 'U04JS3K201J', message: "project_0179: #{log_message}")
          rescue ActiveRecord::ConnectionTimeoutError
            sleep(5)
            retry
          rescue StandardError => e
            log_message = "----Error: #{thread_num}------pick: #{file_path}"
            @logger.info(log_message)
            @logger.info(e.full_message)
            Hamster.report(to: 'U04JS3K201J', message: "project_0179: #{log_message}")
            puts e.full_message
            @semaphore.synchronize {
              files << file_path
            }
            sleep(3600)
          end
        end
      end
    end

    threads.each(&:join)
    Hamster.report(to: 'U04JS3K201J', message: "project_0179: #{@court_type} Storing Done!")
  end

  def ban_proxy(proxy)
    @semaphore.synchronize {
      puts "=-=-=-=-=-=-=-=-=ban_proxy-=-=-=-=-=-=-=-#{proxy}".red
      if @baned_proxies[proxy]
        @baned_proxies[proxy][:touches] += 1
        @baned_proxies[proxy][:start] = Time.now
      else
        @baned_proxies[proxy] = { start: Time.now, touches: 1 }
      end
    }
  end

  def baned_proxy?(proxy)
    return false unless @baned_proxies.keys.include?(proxy)
    
    Time.now - @baned_proxies[proxy][:start] < 2.hours
  end

  def using_on(proxy)
    puts "------------using proxy now------------#{proxy}".greenish
    @semaphore.synchronize {
      @using_proxies[proxy] = { start: Time.now, touches: 1 }
    }
  end

  def valid_proxy?(proxy)
    return false if baned_proxy?(proxy)

    return true unless @using_proxies.keys.include?(proxy)
  end

  private

  def parse_and_store(file_path)
    file_data = File.read(file_path).split
    unless file_data.count.zero?
      connector   = MarylandConnector.new(Scraper::START_PAGE)
      retry_count = 0
      loop do
        begin
          case_id = file_data.shift

          break if case_id.nil?

          case_path = "#{Scraper::BASE_PATH}/casesearch/#{case_id}"
          case_page = connector.do_connect(case_path)
          hash      = @parser.parse_case_info(case_page.body, case_path)
          @keeper.add_records(hash)
        rescue StandardError => e
          file_data << case_id
          retry_count += 1

          if retry_count > MAX_RETRY
            File.open(file_path, 'w+') do |f|
              f.puts(file_data.uniq)
            end

            raise e
          else
            retry
          end
        end
      end
    end
    File.delete(file_path) if File.exist?(file_path)
  end
end
