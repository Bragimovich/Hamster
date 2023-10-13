class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200,304].include?(response.status) }
  end

  def download_zip_file(url, zip_file_name)
    retries = 0
    begin
      response = connect_to(url: url, method: :get_file, filename: "#{storehouse}/store/#{zip_file_name}", proxy_filter: @proxy_filter, ssl_verify: false)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  def get(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter, ssl_verify: false)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

end
