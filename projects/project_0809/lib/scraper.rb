# frozen_string_literal: true

class Scraper < Hamster::Scraper
    
  def get_main_response
    connect_to(url: 'https://apps.myocv.com/feed/rtjb/a36160187/InmateSearch', method: :get)
  end

  def fetch_image(link)
    connect_to(link)
  end
  
end
