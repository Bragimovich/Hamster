# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def main_page
    page = connect_to("https://centralmagistrate.bexar.org/Home/GetRecentArrests?")
    json = JSON.parse(page.body)
    json["data"]
  end

  def details_page(inmate_num)
    page = connect_to("https://centralmagistrate.bexar.org/Home/Details/#{inmate_num}")
    page.body
  end
end
