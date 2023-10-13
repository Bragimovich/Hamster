# frozen_string_literal: true

class Scraper < Hamster::Scraper
  
  URL = "https://uasys.edu/system-office/open-checkbook/"
  TIMEOUT_SECONDS = 50

  def initialize
    super
    @hammer = Dasher.new(using: :hammer,  headless: true)
    @browser = @hammer.connect
    Hamster.logger.debug "Initialized"
  end

  def get_detail_link(year)
    rlt = []
    response = connect_to(url: URL)
    doc = Nokogiri::HTML(response.body)
    doc.css('#tablepress-41 tbody tr').each do |tr_tag|
      next unless tr_tag.text.include?(year.to_s)
      if tr_tag.text.include?('Fiscal Year') || tr_tag.text.include?('FY')
        
        link = {
          data_type: tr_tag.css('.column-2 a').text.downcase.strip,
          href: tr_tag.css('.column-2 a').attr('href').value
        }
        rlt << link
        link = {
          data_type: tr_tag.css('.column-3 a').text.downcase.strip,
          href: tr_tag.css('.column-3 a').attr('href').value
        }
        rlt << link
      end
    end
    rlt
  end

  def landing_page(url)
    @browser.go_to(url)
    time_out = TIMEOUT_SECONDS
    sleep 3
    doc = Nokogiri::HTML(browser.body)
    while doc.css('div.mid-viewport div.row').length == 0
      script_scroll_down_up = "$('button.scrollDown').click();$('button.scrollUp').click();"
      browser.execute(script_scroll_down_up)
      Hamster.logger.debug "Waiting for landing #{url}"
      sleep 3
      time_out = time_out - 1
      if time_out == 0
        raise "Loading Error: #{url} - TimeOut"
      end
      doc = Nokogiri::HTML(@browser.body)
    end
    load_all_data
  end

  def load_all_data
    doc = Nokogiri::HTML(browser.body)
    unless doc.css('div.slicerCheckbox')[0].attr('class').include?('selected')
      orig_view_md5 = Digest::MD5.hexdigest(get_doc.css('div.mid-viewport div.row').text)
      script_click_select_all ="$('.slicerCheckbox')[0].click();"
      browser.execute(script_click_select_all)      
      script_scroll_down_up = "$('button.scrollDown').click();$('button.scrollUp').click();"
      browser.execute(script_scroll_down_up)
      sleep 5
      doc = Nokogiri::HTML(browser.body)
    end
  end

  # return true if data is loaded
  def go_scroll_down    
    orig_view_md5 = Digest::MD5.hexdigest(get_doc.css('div.mid-viewport div.row').text)
    script_btn_scroll_down_click = "$('button.scrollDown').click();"
    browser.execute(script_btn_scroll_down_click)
    time_out = 30
    sleep 2
    new_view_md5 = Digest::MD5.hexdigest(get_doc.css('div.mid-viewport div.row').text)
    while orig_view_md5 == new_view_md5
      sleep 1
      Hamster.logger.debug 'Sleeping 1 second for scroll down'
      time_out -= 1
      if time_out == 0
        return false
      end
      new_view_md5 = Digest::MD5.hexdigest(get_doc.css('div.mid-viewport div.row').text)
    end
    return true
  end

  def get_doc
    Nokogiri::HTML(browser.body)
  end

  def close_browser
    browser.quit
  end
  
  private
    attr_accessor :browser

end
