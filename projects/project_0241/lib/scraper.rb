class Scraper <  Hamster::Scraper
  MAIN_URL = "https://salaries.texastribune.org/"

  def main_page
    connect_to(MAIN_URL)
  end

  def csv_downloading(csv,run_id,file)
    FileUtils.mkdir_p("#{storehouse}store/#{run_id}/csv")
    Hamster.connect_to(csv, method: :get_file, filename: "#{storehouse}store/#{run_id}/csv/#{file}")
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
  end

end
