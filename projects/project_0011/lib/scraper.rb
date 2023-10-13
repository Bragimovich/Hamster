class Scraper < Hamster::Scraper

  def fetch_main_page
    connect_to("https://data.sba.gov/dataset/ppp-foia")
  end

  def download_file(storehouse, run_id, link, retries = 50)
    begin
      proxy = PaidProxy.all.to_a.shuffle.first
      proxy_string = "#{proxy["loginfile_link"]}:#{proxy["pwd"]}@#{proxy["ip"]}:#{proxy["port"]}"
      system("http_proxy=http://#{proxy_string} wget -P #{storehouse}store/#{run_id} #{link}")
    rescue Exception => e
      raise if retries <= 1
      download_file(storehouse, run_id, link, retries - 1)
    end
  end
end
