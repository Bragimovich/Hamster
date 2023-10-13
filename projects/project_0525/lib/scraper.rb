# frozen_string_literal: true

class Scraper < Hamster::Scraper

  URL = "https://www.msbar.org/lawyer-directory/"

  def scrape(letter)
    break_count = 1
    while true
      if break_count == 5
        response = @browser.body
        break
      end
      @browser = initialize_browser
      @browser.go_to(URL)
      sleep(10)
      @browser.at_css("##{letter}link").focus.click
      sleep(10)
      if result_checking
        response = @browser.body
        break
      else
        close_browser
        break_count += 1
      end
    end
    close_browser
    response
  end

  private

  def result_checking
    @browser.at_css("#LawyerSearchResults").text.scan(/\d+ results/).count > 0 ? true : false
  end

  def initialize_browser
    @hammer = Dasher.new(using: :hammer,  headless: true)
    @hammer.connect
  end

  def close_browser
    @browser.quit
  end
end
