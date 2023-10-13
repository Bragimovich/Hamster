# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def store_to_csv(source, file_name)
    path = "#{storehouse}store/#{file_name}"
    CSV.open(path, 'a') do |csv|
      source.each do |record|
        csv << record.values
      end
    end
  end

  def get_source(url)
    connect_to(url: url, headers: HEADERS)
  end
end
