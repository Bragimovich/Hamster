require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/store'

class Manager < Hamster::Scraper
  SUB_FOLDER = "obituary"

  def initialize
    super
    @parser = Parser.new
    @store = Store.new
    @scraper = Scraper.new
    @connector = TributeConnector.new(Scraper::BASE_URL)
    @have_issue = false
    @captcha_client  = Hamster::CaptchaAdapter.new(:two_captcha_com, timeout:200, polling:10)
  end

  def scrape(date_type)
    seached_data = []
    start_date = Date.today - 5.days
    end_date   = Date.today
    file_name  = "#{start_date.strftime('%m-%d-%Y')}_#{end_date.strftime('%m-%d-%Y')}_#{date_type}"
    file_path  = "#{store_file_path}/#{file_name}"
    
    logger.info "---Started daily scraping for date range(#{start_date.strftime('%m/%d/%Y')} - #{end_date.strftime('%m/%d/%Y')})---#{date_type}"
    
    if date_type == 'odd'
      date_list = (start_date..end_date).select{|d| d.day.odd?}
    else
      date_list = (start_date..end_date).select{|d| d.day.even?}
    end
    date_list.each do |d|
      seached_data.concat @scraper.scrape(d, d)
    end
    logger.info "Scraped data(#{seached_data.count}) to #{file_path}"
    Hamster.report(to: 'U04JS3K201J', message: "st0585: Scraped data(#{seached_data.count}) to #{file_name}")
    store_data(file_path, seached_data)

    store file_path
  end

  def weekly_scrape
    start_date = Date.today - 31
    end_date = Date.today
    file_name = "#{start_date.strftime('%m-%d-%Y')}_#{end_date.strftime('%m-%d-%Y')}"
    file_path = "#{store_file_path}/#{file_name}"

    logger.info "---Started weekly scraping for date range(#{start_date.strftime('%m/%d/%Y')} - #{end_date.strftime('%m/%d/%Y')})---"

    data = @scraper.scrape(start_date, end_date)
    logger.info "Scraped data(#{data.count}) to #{file_path}"
    Hamster.report(to: 'U04JS3K201J', message: "st0585: Scraped data(#{data.count}) to #{file_name}")
    store_data(file_path, data)

    store file_path
  end

  def store(file_path)
    save_data_from(file_path)
    File.delete(file_path) if File.exist?(file_path)
    @store.flush
    # @store.mark_deleted
    @store.finish
    logger.info "---Added all data to DB for this file #{file_path}---"
  rescue => e
    logger.info e.full_message
    @store.flush

    raise e
  end

  def clear
    @store.flush
  end

  def clear_files
    files = Dir.glob(store_file_path + "/*")
    FileUtils.rm_rf files
  end

  private

  class SwapProxyAndRetry < StandardError; end
  class SolvedCaptchaAndRetry < StandardError; end
  class CaptchaSolveRequiredError < StandardError; end

  def save_data_from(file)
    max_retry_count = 15
    file_data = File.read(file).split("\n")
    file_data.each do |data|
      next if [data['fullName'], data['city'], data['state'], data['funeralHomeName']].include?(nil)

      retry_count      = 0
      data             = eval(data)
      obituary         = {}
      full_name        = data['fullName']
      obituary_id      = data['obituaryId']
      detail_url       = "#{Scraper::BASE_URL}/archiveapi/obituary/#{obituary_id}/#{full_name&.parameterize}"
      query_path       = "#{obituary_id}/#{full_name&.parameterize}/#{data['city']&.parameterize}/#{data['state']&.parameterize}/#{data['funeralHomeName']&.parameterize}"
      detail_page_url  = "https://www.tributearchive.com/obituaries/#{query_path}"

      obituary[:obituary_details] = data
      logger.debug detail_url

      begin
        unless @have_issue
          obituary_details      = @connector.do_connect(detail_url)
          obituary_details_body = JSON.parse(obituary_details.body)
          if obituary_details.status == 200 && obituary_details_body.keys.include?("showCaptcha")
            obituary[:obituary_details]['show_captcha'] = obituary_details_body['showCaptcha']
            obituary[:obituary_details]['public_key']   = obituary_details_body['publicKey']
            logger.debug obituary_details_body
            logger.debug detail_page_url
            solved = solve_captcha!(obituary_details_body, detail_page_url)

            raise SolvedCaptchaAndRetry if solved
          else
            obituary[:obituary_details] = obituary_details_body
          end
        end

        # event_url = "#{Scraper::BASE_URL}/archiveapi/obituary/#{obituary_id}/events"
        # obituary_events, = @connector.do_connect(event_url)
        # obituary[:obituary_events] = JSON.parse(obituary_events.body) if obituary_events&.success?
        data_hash = @parser.parse_json(obituary, detail_url)
        @store.store_data(data_hash)
      rescue SolvedCaptchaAndRetry
        logger.debug 'solved captcha and retry'

        retry
      rescue StandardError => e
        logger.info e.full_message

        if retry_count >= max_retry_count
          @store.flush
          # @have_issue = true

          # Hamster.report(to: 'U04JS3K201J', message: "st0585: Tried 15 times to solve the captcha, skip for protecting proxy ban problem")
          Hamster.report(to: 'U04JS3K201J', message: "st0585: Tried 15 times to solve the captcha, next obituary")
          next
        end

        @connector.update_proxy_and_token        
        retry_count += 1

        retry
      end
    end
  end

  def solve_captcha!(body, detail_page_url)
    max_retry_count  = 15
    retry_count      = 0
    response         = nil
    begin
      req_body       = {key: body['publicKey'], response: captcha_token(detail_page_url)}
      response       = @connector.do_connect(Scraper::CONFIRM_URL, method: :post, data: req_body)
      logger.debug "#{response&.body}\n"

      return true if response.body.to_s.include?('true')

      raise CaptchaSolveRequiredError
    rescue => e
      raise e if retry_count > max_retry_count

      retry_count += 1
      retry
    end
  end

  def store_data(file_path, data)
    ob_ids = data.map{|v| v['obituaryId']}
    exist_ids = RawTributearchive.where(obituary_id: ob_ids).collect(&:obituary_id)
    new_data = data.select{ |v| exist_ids.exclude?(v['obituaryId']) }
    Hamster.report(to: 'U04JS3K201J', message: "st0585: Filter and Stored data(#{new_data.count})")
    File.open(file_path, 'w+') do |f|
      f.puts(new_data)
    end
  end

  def store_file_path
    store_path = "#{storehouse}store"
    FileUtils.mkdir_p(store_path)
    store_path
  end

  def captcha_token(pageurl)
    max_retry_count = 3
    retry_count = 0
    
    raise '2captcha balance is unavailable' if @captcha_client.balance < 1

    min_score = rand(0.3..0.5).round(1)
    options = {
      googlekey: '6LfZc0kaAAAAAHJ0WnYZ1Vui2L6wk_fd36Lus4Su',
      pageurl: pageurl,
      action: 'loadObituary',
      min_score: min_score
    }
    begin
      decoded_captcha = @captcha_client.decode_recaptcha_v3!(options)
      decoded_captcha.text
    rescue StandardError, Hamster::CaptchaAdapter::CaptchaUnsolvable, Hamster::CaptchaAdapter::Timeout, Hamster::CaptchaAdapter::Error
      return if retry_count > max_retry_count
      sleep(10)

      retry_count += 1
      retry
    end
  end
end
