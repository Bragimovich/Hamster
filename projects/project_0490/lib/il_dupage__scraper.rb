# frozen_string_literal: true

class IlDuPageScraper < Hamster::Scraper

  SOURCE_API = 'https://search.dupagesheriff.org/api/Inmates/InmateApi/List'
  SOURCE_PAGE = 'https://search.dupagesheriff.org/inmate/list'
  LIMIT = 1000

  def initialize
    super
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    # @session_id = 'spieplp21jd0ma4hofzxiwv4'
    @session_id = 'dpvymepk13j354cty0nzk41s'
  end

  def download

    captcha_status = get_captcha_validation_status
    unless captcha_status["IsSuccessful"]
      captcha_text = solve_captcha
      return if captcha_text.nil?

      captcha_status = validate_captcha_response(captcha_text)
      return unless captcha_status["IsSuccessful"]
    end

    post_list_request
  end

  def get_page(url_file)
    connect_to(url_file, proxy_filter: @filter, ssl_verify: false)&.body
  end

  def connect_to_page
    connect_to(SOURCE_PAGE, proxy_filter: @filter, ssl_verify: false)&.body
  end

  private

  def get_captcha_validation_status
    request_url = "https://search.dupagesheriff.org/api/Captcha/Captcha/GetCaptchaValidationStatus"
    headers = { Cookie: "ASP.NET_SessionId=#{@session_id}" }
    response = connect_to(request_url, proxy_filter: @filter, ssl_verify: false, headers: headers)&.body
    JSON.parse(response)
  end

  def post_list_request
    payload = { SearchCriteria: {}, PageSize: LIMIT, PageNumber: 1 }.to_json
    headers = { Cookie: "ASP.NET_SessionId=#{@session_id}", Content_Type: "application/json" }
    response = connect_to(SOURCE_API,
                          proxy_filter: @filter,
                          ssl_verify: false,
                          method: :post,
                          req_body: payload,
                          headers: headers)&.body
    response
  end

  def solve_captcha
    options = {
      pageurl: "https://search.dupagesheriff.org/inmate/list",
      googlekey: "6LdIiCMUAAAAAMpEP6dAar-s2YxT4JQNUUMzqHHm"
    }

    captcha_solver = Hamster::CaptchaSolver.new(timeout: 120, polling: 10)

    money = captcha_solver.balance
    puts "Captcha balance: #{money}"
    if money < 0
      Hamster.report message: "Project #490 2captcha balance < 0. Finishing task...", to: 'U031HSK8TGF'
      return nil
    elsif money < 1
      Hamster.report message: "Project #490 2captcha balance < 1. Needs urgent refill...", to: 'U031HSK8TGF'
    else
      Hamster.report message: "Project #490 2captcha balance: #{money}", to: 'U031HSK8TGF'
    end

    decoded_captcha = captcha_solver.decode_recaptcha_v2!(options)
    decoded_captcha.text
  rescue StandardError => e
    puts e, e.full_message
    Hamster.report message: "Project #490 solve_captcha:\n#{e}", to: 'U031HSK8TGF'
    return nil
  end

  def validate_captcha_response(captcha_text)
    request_url = "https://search.dupagesheriff.org/api/Captcha/Captcha/ValidateCaptchaResponse"
    headers = { Cookie: "ASP.NET_SessionId=#{@session_id}", Content_Type: "application/json" }
    response = connect_to(request_url,
                          proxy_filter: @filter,
                          ssl_verify: false,
                          method: :post,
                          req_body: captcha_text.to_json,
                          headers: headers)
    JSON.parse(response&.body)
  end

end
