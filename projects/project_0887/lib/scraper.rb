# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def fetch_pdf(url)
    dirname = "#{storehouse}store/"
    filename = "#{dirname}" + "#{url.split('/').last}"
    connect_to(url, method: :get_file, filename: filename)
    pdf = PDF::Reader.new(filename)
  end
end
