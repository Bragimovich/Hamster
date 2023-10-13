# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def download(url)
    dirname = "#{storehouse}store/"
    file_name = "#{dirname}inmate.pdf"
    connect_to(url, method: :get_file, filename: file_name, ssl_verify: false)
    pdf = PDF::Reader.new(file_name)
  end
end
