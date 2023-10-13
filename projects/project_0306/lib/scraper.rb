# frozen_string_literal: true

class Scraper <  Hamster::Scraper

  def download(sub_folder)
    system("wget https://apps.irs.gov/pub/epostcard/data-download-epostcard.zip -O #{storehouse}store/#{sub_folder}/file.zip")
  end

end
