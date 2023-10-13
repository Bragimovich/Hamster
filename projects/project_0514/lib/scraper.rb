class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_main_page
    url = "https://ope.ed.gov/athletics/api/dataFiles/fileList"
    connect_to(url: url, method: :get)
  end

  def get_zip_file(file_name)
    url = "https://ope.ed.gov/athletics/api/dataFiles/file?fileName=#{file_name}"
    connect_to(url: url, method: :get)
  end

  private

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end
end
