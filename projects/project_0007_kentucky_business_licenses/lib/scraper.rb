# frozen_string_literal: true

HEADERS = {
  # 'user-agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.104 Safari/537.36',
  # 'read_timeout' => '10',
  'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
  'authority' => 'web.sos.ky.gov',
}

class Scraper < Hamster::Scraper

  URL = "https://web.sos.ky.gov/bussearchnprofile/search"
  TIMEOUT_SECONDS = 10
  def initialize
    super
    @hammer = Dasher.new(using: :hammer,  headless: true)
    @browser = @hammer.connect
  end
  
  def landing(url = URL)
    browser.go_to(url)
    sleep 1
    js_script_enable_search = '$( "#MainContent_cbActiveonly" ).prop( "checked", false );'
    retries = 4
    begin
      browser.execute(js_script_enable_search)
    rescue Exception => e
      if e.full_message.include?("$ is not defined")
        raise "no_response_on_landing"
      end
      retries -= 1
      logger.debug "Re-running browser, retries: #{retries}"
      unless browser.nil? 
        browser.quit rescue nil
      end
      @hammer = Dasher.new(using: :hammer,  headless: true)
      browser = @hammer.connect
      sleep 1
      browser.go_to(url)
      raise "landing error" if retries == 0
      retry 
    end
  end

  def reset_browser
    browser.reset
    sleep 0.5
  end

  def get_detail(url)
    if browser.current_url != url
      browser.go_to(url)
      sleep 1
    end
    doc = get_doc
    time_out = TIMEOUT_SECONDS
    while doc.css('#MainContent_pInfo table')[0].nil? && doc.css('#MainContent_pInfo table')[0].length == 0
      sleep 0.2
      time_out -= 1
      doc = get_doc
      raise "no_response_on_search" if time_out == 0
    end
    # Show Current Officers
    if get_doc.at_css('#MainContent_BtnCurrent')
      js_script = "$('#MainContent_BtnCurrent').click();"
      browser.execute(js_script)
      time_out = TIMEOUT_SECONDS
      while get_doc.at_css('#MainContent_pcurrent').nil?
        sleep 0.2
        time_out -= 1
        raise "no_response_on_show_current_officers_button" if time_out == 0
      end
      b_officers = true
    end
    # Show Initial Officers
    if get_doc.at_css('#MainContent_BtnInitial')
      js_script = "$('#MainContent_BtnInitial').click();"
      browser.execute(js_script)
      time_out = TIMEOUT_SECONDS
      while get_doc.at_css('#MainContent_PnlIOff').nil?
        sleep 0.2
        time_out -= 1
        raise "no_response_on_show_initial_officers_button" if time_out == 0
      end
    end
    get_doc
  end

  def search_bussearchnprofile(keyword)
    js_script = "$('#MainContent_txtSearch').val('#{keyword}');"
    js_script += "$('#MainContent_BSearch').click();"
    browser.execute(js_script)
    doc = Nokogiri::HTML(browser.body)
    
    time_out = 40
    while !doc.text.include?("No matching organizations were found") && doc.css('#MainContent_PSearchResults').length == 0
      sleep 0.2
      time_out -= 1
      doc = Nokogiri::HTML(browser.body)
      if doc.css('#MainContent_pInfo table').length > 0
        raise "redirected_to_detail_page"
      end
      if time_out == 0
        raise "no_response_on_search"         
      end
    end
  end

  def get_doc
    Nokogiri::HTML(browser.body)
  end

  def get_current_url
    browser.current_url rescue nil
  end

  def clear_bussearchnprofile
    js_script = "$('#MainContent_BClear').click();"
    browser.execute(js_script)
    doc = Nokogiri::HTML(browser.body)
    time_out = TIMEOUT_SECONDS
    while doc.css('#MainContent_PSearchResults').length != 0
      sleep 1
      time_out -= 1
      doc = Nokogiri::HTML(browser.body)
      raise "no_respond_on_clear_bussearchnprofile" if time_out == 0
    end
  end
  
  def is_next_page
    get_doc.css('a#MainContent_LbNext').length > 0
  end

  def go_next_page
    return unless is_next_page
    js_script = get_doc.css('a#MainContent_LbNext')[0].attr('href')
    browser.execute(js_script)
    doc = get_doc
    time_out = TIMEOUT_SECONDS
    while !doc.css('a#MainContent_LbNext')[0].nil? && doc.css('a#MainContent_LbNext')[0]['href'] == js_script
      sleep 0.2
      doc = get_doc
      time_out -= 1
      raise "no_respond_on_go_next_page" if time_out == 0
    end
  end

  def close_browser
    browser.quit unless browser.nil?
  end

  private
    attr_accessor :browser

end
