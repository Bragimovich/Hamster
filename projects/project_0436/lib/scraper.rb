class Scraper <  Hamster::Scraper
  MAIN_URL = "https://transparentnevada.com/agencies/salaries/"
  DOMAIN = "https://transparentnevada.com"

  def main_page
    connect_to(MAIN_URL)
  end

  def link_connect(link)
    connect_to(link)
  end

  def link_connect_inner(link)
    connect_to(DOMAIN + link)
  end

  def csv_downloading(csv,run_id,file)
    FileUtils.mkdir_p("#{storehouse}store/#{run_id}")
    Hamster.connect_to(csv, method: :get_file, filename: "#{storehouse}store/#{run_id}/#{file}")
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

end
