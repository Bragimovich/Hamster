require_relative '../lib/parser'
require_relative '../lib/message_send'

class Scraper < Hamster::Scraper
  def initialize
    super
    @captcha_client = Hamster::CaptchaAdapter.new(:two_captcha_com, timeout: 200, polling: 10)
    @proxy_filter = ProxyFilter.new(duration: 600, touches: 100)
  end

  def search_results(search_string)
    parser = Parser.new
    url = 'https://courtsportal.dallascounty.org/DALLASPROD/Home/Dashboard/29'
    browser = Hamster::Scraper::Dasher.new(using: :hammer, pc: 1).connect
    browser.go_to(url)
    browser.at_xpath('//*[@id="caseCriteria_SearchCriteria"]').focus.type(search_string)
    browser.at_xpath('//*[@id="AdvOptions"]').click
    sitekey = parser.sitekey(browser)
    options = {
      pageurl: url,
      googlekey: sitekey
    }
    logger.info "Captcha balance: #{@captcha_client.balance}".yellow
    if @captcha_client.balance < 1
      logger.info "Low balance. Wait..."
      sleep 600
      retry
    end
    decoded_captcha = @captcha_client.decode_recaptcha_v2!(options)
    js_script = "document.getElementById('g-recaptcha-response').innerHTML='#{decoded_captcha.text}';"
    browser.execute(js_script)
    keys = %i[Ctrl Shift Left]
    browser.at_xpath('//*[@id="AdvOptionsMask"]/div[1]/div/div/div[2]/div/span/span/input').focus.type(2.times.map { keys }, :backspace).type("Case Number")
    browser.at_xpath('//*[@id="caseCriteria_SearchBy_listbox"]/li').click
    browser.at_xpath('//*[@id="caseCriteria.FileDateStart"]').focus.type("01/01/2016")
    browser.at_xpath('//*[@id="btnSSSubmit"]').focus.click
    logger.info 'Search page'
    (1..8).each do |sec|
      logger.info "Loading... (#{9-sec} sec)"
      sleep(1)
    end
    cases = parser.cases(browser)
    if cases.blank? || (cases.select{|item| item[:case_id].include?(search_string.gsub('*',''))}.blank? && cases.select{|item| item[:case_id].include?(search_string.gsub('*','').gsub('-',''))}.blank?)
      return nil
    end
    (2..).each do |page_number|
      pages = parser.pages(browser)
      page_numbers = []
      pages.each do |page|
        page_numbers << page.text.strip
      end
      if page_numbers.include?(page_number.to_s) || page_numbers.include?('...')
        browser.at_css("#CasesGrid > div > ul > li > a[data-page='#{page_number}']").focus.click
        logger.info "Page #{page_number}"
        (1..3).each do |sec|
          logger.info "Loading... (#{4-sec} sec)"
          sleep(1)
        end
        cases += parser.cases(browser)
      else
        break
      end
    rescue => e
      message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
      logger.error message
      break
    end
    return cases
  rescue => e
    message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
    logger.error message
  ensure
    browser.quit
    Process.waitall
    GC.start(immediate_sweep: false)
  end

  def relocation(link)
    retry_count = 0
    begin
    hamster = Hamster.connect_to(link, proxy_filter: @proxy_filter, ssl_verify: false)
    location = "https://courtsportal.dallascounty.org#{hamster.headers['location']}"
    location
    rescue StandardError => e
      logger.error e.full_message
      if retry_count < 5
        retry_count += 1
        retry
      end
    end
  end

  def page(link)
    retry_count = 0
    begin
      Hamster.connect_to(link, proxy_filter: @proxy_filter, ssl_verify: false)
    rescue => e
      if retry_count < 5
        retry_count += 1
        retry
      else
        message = "Error: #{e.message}\nBacktrace: #{e.backtrace}"
        logger.error message
        message_send(message)
      end
    end
  end
end
