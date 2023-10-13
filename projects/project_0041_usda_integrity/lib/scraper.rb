class Scraper < Hamster::Scraper
  def initialize
    super
  end

  def download_xlsx
    url = 'https://organic.ams.usda.gov/Integrity/Search.aspx'
    @xlsx_folder = 'usda_activities'

    @browser = Hamster::Scraper::Dasher.new(url,
                                            using: :hammer, hammer_opts:
                                              { headless: false, save_path: @xlsx_folder, timeout: 10000 }).smash
    js_code = "javascript:__doPostBack('ctl00$MainContent$lbtnExportToExcel','')"
    @browser.go_to(js_code)
    sleep 300
    @browser.quit
  end
end
