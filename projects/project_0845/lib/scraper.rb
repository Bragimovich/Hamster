require_relative 'parser'
require_relative 'connector'
class Scraper < Hamster::Scraper
  HOST = 'https://webapps.hcso.tampa.fl.us'
  BASE_URL = "#{HOST}/ArrestInquiry/"
  def initialize
    super
    @captcha_client = Hamster::CaptchaAdapter.new(:two_captcha_com, timeout:200, polling:10)
    @connector      = FlInmateConnector.new(BASE_URL)
    @parser         = Parser.new
    @aws_s3         = AwsS3.new(:hamster, :hamster)
  end

  def search(letter)
    form_data = {
      'SearchName' => letter,
      'SearchIncludeDetails' => false,
      'SearchSortType' => 'BOOKNO',
      'g-recaptcha-response' => captcha_token(BASE_URL),
      'SearchCurrentInmatesOnly' => false
    }
    begin
      response = @connector.do_connect(BASE_URL, method: :post, data: form_data)
      
      raise InvalidCaptchaError if @parser.invalid_captcha?(response.body)
    rescue InvalidCaptchaError => e
      raise e if retry_count > 5
      form_data['g-recaptcha-response'] = captcha_token(BASE_URL)

      retry_count += 1
      retry
    rescue => e
      logger.info "Not found search page(#{url})"

      nil
    end
    response
  end

  def scrape_per_page(letter, page)
    retry_count = 0
    form_data = {
      'ResultsPerPage' => 200,
      'SearchName' => letter,
      'SearchIncludeDetails' => false,
      'SearchSortType' => 'BOOKNO',
      'SearchCurrentInmatesOnly' => false,
      'SearchResults.CurrentPage' => page,
      'SearchResults.PageSize' => 200
    }
    begin
      response = @connector.do_connect(BASE_URL, method: :post, data: form_data)
      
      raise InvalidCaptchaError if @parser.invalid_captcha?(response.body)
    rescue InvalidCaptchaError => e
      logger.info "============ scrape_per_page invalid captcha ============"
      logger.info form_data
      
      raise e if retry_count > 5

      form_data['g-recaptcha-response'] = captcha_token(BASE_URL)

      retry_count += 1
      retry
    rescue => e
      logger.info "Not found page: #{page}, letter: #{letter}"

      nil
    end
    response
  end

  def detail_page(detail_page_url)
    @connector.do_connect(detail_page_url)
  rescue => e
    logger.info "Not found detail page(#{detail_page_url})"

    nil
  end

  def upload_to_aws(photo_url, full_name, inmate_id)
    return unless photo_url
    return if photo_url.include?('unknown.jpg')

    begin
      response  = @connector.do_connect(photo_url)
      content   = response.body if response
      key       = "inmates/fl/hillsborough/#{full_name.parameterize.underscore}_#{inmate_id}.jpg"
      @aws_s3.put_file(content, key) if content
    rescue => e
      logger.info "404 not found mugshot url: #{photo_url}"
      logger.info e.full_message

      return
    end
  end

  private

  class InvalidCaptchaError < StandardError; end

  def captcha_token(pageurl)
    retry_count     = 0
    max_retry_count = 5

    raise '2captcha balance is unavailable' if @captcha_client.balance < 1

    options = {googlekey: '6LdMkrsUAAAAAHzYKwFUq90nkLEk9EEW04RVQbtV', pageurl: pageurl}
    begin
      decoded_captcha = @captcha_client.decode_recaptcha_v2!(options)
      decoded_captcha.text
    rescue StandardError, Hamster::CaptchaAdapter::CaptchaUnsolvable, Hamster::CaptchaAdapter::Timeout, Hamster::CaptchaAdapter::Error
      return if retry_count > max_retry_count
      sleep(10)

      retry_count += 1 
      retry
    end
  end
end
