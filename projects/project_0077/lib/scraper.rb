# frozen_string_literal: true


##

class Scraper < Hamster::Scraper

  URL = "https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-Present/ijzp-q8t2"
  URL_CSV = "https://data.cityofchicago.org/api/views/ijzp-q8t2/rows.csv?accessType=DOWNLOAD"
  FILENAME = "crimes_2001_to_present.csv"

  def initialize(args)
    super

    if args[:debug]
      @debug = true
    end
  end

  def download
      connect_to( URL )
      connect_to(URL_CSV, method: :get_file, filename: storehouse+"store/" + FILENAME)
  end

  def delete_file
    peon.move_all_to_trash
    peon.throw_trash(0)
  end

end
