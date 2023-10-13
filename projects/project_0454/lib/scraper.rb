# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def download_csv(source)
    puts ['*'*77, "Download csv from #{source}"]
    file_name = Hamster::Parser.new.storehouse + "store/" + Time.now.to_s.split[0] + "-globaldothealth.csv"
    connect_to(source, method: :get_file, filename: file_name)
    file_name
  end

end
