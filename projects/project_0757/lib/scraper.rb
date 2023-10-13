class Scraper < Hamster::Scraper

  def initialize
    super
    @cobble = Dasher.new(using: :cobble, redirect: true)
    @hammer = Dasher.new(using: :hammer, redirect: true)
  end

  def download_main_html_page(url)
    @browser = @hammer.connect
    @browser.go_to(url)
    sleep 5
    html_page = @browser.body
    @browser.quit

    html_page
  end

  def download_cvs_file(url)
    @cobble.get_file(url, filename: "bank-data_#{Date.today.strftime("%m-%d-%Y")}.csv")
  end
end
