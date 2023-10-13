# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/scraper'

class ScraperBrowser < Scraper

  def initialize
    super
  end

  def start_browser
    begin
      retries ||= 0
      logger.debug "starting browser"
      @hammer = Dasher.new(using: :hammer, headless: true, proxy_filter: @proxy_filter)
      @browser = @hammer.connect
    rescue Ferrum::ProcessTimeoutError, Ferrum::TimeoutError => e
      logger.error(e)
      retry if (retries += 1) < 11
    end
  end

  def close_browser
    logger.debug "closing browser"
    @browser.quit rescue nil
    @hammer.close rescue nil
  end
  
  
  def download_page(link)
    return if link.nil?

    logger.debug "#{absolute_url(link)}"
    response = nil
    2.times do
      browser.go_to(absolute_url(link))
      logger.debug browser.current_url.to_s
      browser.wait_for_reload(10)
      break if browser.current_url == absolute_url(link)
    end
    
    # browser.screenshot(path: 'screenshot.png')
    response = browser&.body
  end

  def search_cases(search_character, start_date, end_date)
    begin
      response = nil
      logger.debug "search_cases #{start_url}"
      browser.go_to(start_url)
      logger.debug browser.current_url.to_s
      
      all_records = browser.css('a.ssSearchHyperlink')&.first
      # browser.screenshot(path:"#{storehouse}trash/a.png")
      if all_records
        logger.debug "all_records link found"
        all_records.focus.click
        browser.wait_for_reload(30)
        # browser.screenshot(path:"#{storehouse}trash/b.png")
      else
        logger.debug "all_records link not found".red
        return response
      end
      search_button = browser.css('input[id="SearchSubmit"]')&.first
    
      unless search_button
        logger.warn "search_button not found" 
        # close_browser
        return response
      end

      unless search_button.focusable?
        logger.warn "search button is not focusable"
      end
      
      #fillform
      logger.debug "filling last name: #{search_character}"
      last_name = wait_for('input[id=LastName]', wait:2)
      last_name.focus.type(search_character) if last_name
      logger.debug "filling filed start_date: #{start_date}"
      logger.debug "filling filed end_date: #{end_date}"
      browser.at_css('input[id=DateFiledOnAfter]').focus.type(start_date)
      browser.at_css('input[id=DateFiledOnBefore]').focus.type(end_date)
      # click soundex
      browser.at_css('input[id="chkSoundex"]').focus.click
      search_button = browser.css('input[id="SearchSubmit"]')&.first
      #submit form
      if search_button.focusable?
        logger.debug "clicking button"
        search_button.focus.click
        browser.wait_for_reload(30)
        wait_for('th[class=ssSearchResultHeader]', wait:2)
        
        response = browser&.body
      else
        # 
      end
      
      response
    rescue Ferrum::NodeNotFoundError, Ferrum::TimeoutError  => e
      logger.error e
      
      nil
    end
  end

  def search_cases_by_filed_date(start_date , end_date)
    begin
      response = nil
      # 2.times do
        browser.go_to(start_url)
        sleep(2)
        browser.at_css('a.ssSearchHyperlink').focus.click
        sleep(2)
        # browser.go_to(@search_url)
        logger.debug browser.current_url.to_s
        # browser.wait_for_reload(10)
      # end
      search_button = browser.css('input[id="SearchSubmit"]')&.first
    
      unless search_button
        logger.warn "search_button not found" 
        # close_browser
        return response
      end

      unless search_button.focusable?
        logger.warn "search button is not focusable"
      end
      
      #fillform
      browser.at_css('input[id="DateFiled"]').focus.click
      
      f_start_date = wait_for('input[id=DateFiledOnAfter]', wait:2)
      
      f_end_date = wait_for('input[id=DateFiledOnBefore]', wait:2)
      logger.debug "filling filed date"
      f_start_date.focus.type(start_date)
      sleep(2)
      f_end_date.focus.type(end_date)
      browser.screenshot(path:"1.png")
      #submit form
      sleep(2)
      search_button = browser.css('input[id="SearchSubmit"]')&.first
      if search_button.focusable?
        logger.debug "clicking button"
        search_button.focus.click
        browser.wait_for_reload(20)
        sleep(2)
        response = browser&.body
      else
        # 
      end
      sleep(2)
      # browser.screenshot(path:"2.png")
      response
    rescue Ferrum::NodeNotFoundError => e
      logger.error e
      nil
    end
  end

  private 
  
  attr_accessor :browser

  def wait_for(want, init:nil, wait:1, step:0.1)
    sleep(init) if init
    meth = want.start_with?('/') ? :at_xpath : :at_css
    until node = browser.send(meth, want)
      (wait -= step) > 0 ? sleep(step) : break
    end
    node
  end

  def req_headers
    {
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'Accept-Language': 'en-US,en;q=0.9',
      'Connection': 'keep-alive',
      'Host': 'ccmspa.pinellascounty.org',
      "Referer" => @search_url
    }
  end
end
