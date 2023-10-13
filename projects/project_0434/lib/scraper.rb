class Scraper < Hamster::Scraper

  def landing_page
    @browser = initialize_browser
    @browser.go_to("https://www.azcentral.com/pages/interactives/news/local/arizona-data/arizona-government-salary-database/")
    sleep(10)
    @browser.body
  end

  def visit_link(link)
    @browser.create_page
    @browser.pages.last.go_to(link)
    sleep(3)
    body = @browser.pages.last.body
    @browser.pages.last.close
    sleep(0.75)
    body
  end

  def next_page
    @browser.css('a[data-cb-name="JumpToNext"]').last.focus.click
    sleep(10)
    @browser.body
  end

  def skip_pages(counter)
    reset_counter = 1
    while reset_counter < counter
      @browser.css('a[data-cb-name="JumpToNext"]').last.focus.click
      sleep(3)
      reset_counter += 1
    end
    [reset_counter, @browser.body]
  end

  def close_browser
    @browser.quit
  end

  private

  def initialize_browser
    @hammer = Dasher.new(using: :hammer,  headless: true)
    @hammer.connect
  end
end
