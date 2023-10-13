# frozen_string_literal: true

class Scraper < Hamster::Scraper

  URL = "https://apps.tn.gov/tncamp/public/cpsearch.htm"

  def initialize
    super
    @hammer = Dasher.new(using: :hammer,  headless: true)
    @browser = @hammer.connect
  end

  def landing_page
    browser.go_to(URL)
  end

  def landing_page_ce
    browser.go_to(URL)
    cookie = browser.cookies.all.values[0].value
    cookies = "JSESSIONID=" + cookie
  end

  def do_search(party_id)
    landing_page
    browser.at_css("#rdoCandidate").focus.click
    sleep(1)
    @processed_checks = []
    switch_find("#rdoCandidate")
    mark_checkboxes('candi')
    switch_find("#rdoPAC")
    mark_checkboxes('pac')
    browser.at_css("#rdoBoth").focus.click
    sleep(1)
    party_selection(party_id)
    browser.css('input[type="submit"]').last.focus.click
    sleep(2.5)
    fetch_pages(party_id)
  end

  def close_browser
    browser.quit
  end

  def ce_request(report_url, cookies)
    headers = {}
    headers["Cookie"] = cookies
    connect_to(url: report_url, headers: headers)
  end

  private

  attr_accessor :browser

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304, 302, 307].include?(response.status)
    end
    response
  end

  def fetch_pages(party_id)
    pages_array = []
    page_no = 1
    while true
      pages_array << {
        "Party_ID": party_id,
        "Page_Number": page_no,
        "HTML": browser.body
      }
      break if browser.css('a').select{|e| e.text.include? 'Next'}.empty?
      page_no += 1
      browser.css('a').select{|e| e.text.include? 'Next'}.first.focus.click
      sleep(2.5)
    end
    pages_array
  end

  def party_selection(party_id)
    browser.css('a[class="chosen-single"]').last.focus.click
    sleep(1)
    browser.css('li[class="active-result"]')[party_id].click
  end

  def switch_find(type)
    browser.at_css(type).focus.click
    sleep(1)
  end

  def mark_checkboxes(type)
    position = browser.css("input[type='checkbox']").first.find_position
    browser.mouse.scroll_to(position.first, position.last)
    browser.css("input[type='checkbox']").each do |checkbox|
      if checkbox.focusable?
        next if checkbox.attribute('checked') == ''
        checkbox.focus.click unless @processed_checks.include? checkbox.attribute('name') and checkbox.attribute("checked").nil?
        @processed_checks << checkbox.attribute('name')
      end
    end
  end
end
