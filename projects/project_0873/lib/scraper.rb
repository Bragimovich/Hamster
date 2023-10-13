require_relative 'parser'
class Scraper < Hamster::Scraper
  HOST = 'https://www20.state.nj.us'
  TERMS_URL = "#{HOST}/DOC_Inmate/inmatefinder?i=I"
  SEARCH_PAGE = "#{HOST}/DOC_Inmate/inmatesearch"
  def initialize
    super
    @hammer = Hamster::Scraper::Dasher.new(using: :hammer, pc: 1, headless: true)
    @browser = nil
    @parser = Parser.new
  end

  def search(letter, county)
    set_browser unless @browser
    @browser.go_to(SEARCH_PAGE)
    wait_for("//input[@name='Submit']")
    begin
      inmate_list = []
      @browser.evaluate("document.querySelector(\"input[name='Last_Name']\").value='#{letter}'")
      @browser.evaluate("document.querySelector(\"select[name='County']\").querySelector(\"option[value='ALL']\").selected=false")
      @browser.evaluate("document.querySelector(\"select[name='County']\").querySelector(\"option[value='#{county}']\").selected=true")
      @browser.evaluate("document.querySelector(\"form[name='inmatesearch']\").submit()")
      sleep 10
      parsed_list = @parser.inmate_list(@browser.body)

      return [] if parsed_list.count.zero?

      inmate_list.concat(parsed_list)
      loop do
        break if last_page?

        if @browser.xpath("//div/a[contains(@href,'/DOC_Inmate/results')]").count == 2
          next_page = @browser.at_xpath("//div/a[contains(@href,'/DOC_Inmate/results')][1]/@href").text
        else
          next_page = @browser.at_xpath("//div/a[contains(@href,'/DOC_Inmate/results')][3]/@href").text
        end
        @browser.go_to(HOST + next_page)
        sleep 10
        inmate_list.concat(@parser.inmate_list(@browser.body))
      end
      inmate_list
    rescue => e
      logger.info "Raised error in Scraper#search with letter: #{letter}, county: #{county}"
      accept_terms!

      retry
    end
  end

  def detail_page(url)
    @browser.go_to(url)
    wait_for("//div[@id='mainContent']/table/tbody/tr[2]/td/table/tbody/tr/td[1]/table")
    @browser.body
  end

  def accept_terms!
    retry_count = 0
    begin
      @browser.go_to(TERMS_URL)
      if !@browser.at_xpath("//input[@name='Submit']")
        accept_button = wait_for("//input[@name='inmatesearch']")
        accept_button.click
        wait_for("//input[@name='Submit']")
      end
    rescue => e
      raise e if retry_count > 3

      @hammer.close

      set_browser()
      retry_count += 1
      retry
    end
  end

  private

  class WaitingTimeOutError < StandardError; end

  def set_browser
    @hammer.get(TERMS_URL)
    @browser = @hammer.connection
    @browser.at_xpath("//input[@name='inmatesearch']").click
    sleep 10
  end

  def last_page?
    begin
      return true if @browser.xpath("//div/a[contains(@href,'/DOC_Inmate/results')]").count == 0

      @browser.xpath("//div/a[contains(@href,'/DOC_Inmate/results')]").count == 2 && @browser.at_xpath("//div/a[contains(@href,'/DOC_Inmate/results')][1]/img/@alt").text == 'View the first page'
    rescue => e
      return true
    end
  end
  
  def wait_for(xpath)
    node = nil
    max_time = 60
    sleep_time = 0
    while node.nil?
      break if sleep_time > max_time

      node = @browser.at_xpath(xpath)
      sleep(1)
      sleep_time += 1
    end
    node
  end
end
