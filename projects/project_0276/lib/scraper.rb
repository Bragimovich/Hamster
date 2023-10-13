class Scraper <  Hamster::Scraper

  def initialize
    @hammer = Dasher.new(using: :hammer, pc:1,headless: true)
    @browser = @hammer.connect
    @browser.go_to("https://efdsearch.senate.gov/search/")
  end

  def do_search
    sleep(5)
    if browser.css("input#agree_statement").count == 1
      browser.css("#agree_statement").first.focus.click
    end
    set_form
  end

  def skip_pages(counter)
    page_counter = 1
    while page_counter < counter
      navigate
      sleep(5)
      page_counter += 1
    end
  end

  def close_browser
    @hammer.close
  end

  def fetch_page
    sleep(3)
    next_button = browser.css('a[class="paginate_button next"]').count > 0 ? true : false
    [browser.body, next_button]
  end

  def navigate
    browser.css("#filedReports_next").first.focus.click
    sleep(5)
  end

  def fetch_links
    html_array = []
    all_rows = browser.css('tbody').first.css('tr')
    all_rows.each_with_index do |row, row_index|
      data_hash = {}
      data_hash[:link] = "https://efdsearch.senate.gov#{all_rows[row_index].css('a').first.attribute('href')}"
      browser.css('tbody').first.css('tr')[row_index].css('a').first.focus.click
      sleep(4)
      data_hash[:html] = browser.pages.last.body
      browser.pages.last.close
      waiting_until_element_found('tbody')
      all_rows = browser.css('tbody').first.css('tr')
      html_array << data_hash
    end
    html_array
  end

  attr_accessor :browser, :hammer

  private  

  def set_form
    waiting_until_element_found("#filerTypes")
    browser.css("#filerTypes").first.focus.click
    browser.css("#reportTypes").first.focus.click
    browser.css("#reportTypes").second.focus.click
    browser.css("#fromDate").first.focus.type("01/01/2019")
    browser.css("#toDate").first.focus.type(get_current_date)
    browser.css("button[type='submit']").first.focus.click
    sleep(10)
    sort_results
    sort_results
  end

  def sort_results
    browser.css('th').select{|e| e.text == 'Date Received/Filed'}.first.focus.click
    sleep(3)
  end

  def waiting_until_element_found(search)
    counter = 1
    element = element_search(search)
    while (element.nil?)
      element = element_search(search)
      sleep 1
      break if (element != nil)
      counter +=1
      break if (counter > 20)
    end
    element
  end

  def element_search(search)
    browser.at_css(search)
  end

  def get_current_date
    month = Date.today.month < 10 ? "0#{Date.today.month}" : Date.today.month
    day = Date.today.day < 10 ? "0#{Date.today.day}" : Date.today.day
    "#{month}/#{day}/#{Date.today.year}"
  end
end
