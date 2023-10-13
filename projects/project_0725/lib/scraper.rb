# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def get_file_csv(url)
    base_url = "https://www.gatesfoundation.org"
    response = connect_to(url)
    doc = Nokogiri::HTML(response.body)
    link_csv = base_url + doc.xpath("//span[text()='Download grants data file']/parent::a/@href").text
    filename = link_csv.split('/').last
    response = connect_to(link_csv, method: :get_file, filename: "#{storehouse}store/#{filename}", ssl_verify: false)
    filename
  end
end
