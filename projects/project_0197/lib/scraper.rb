# frozen_string_literal: true

class Scraper < Hamster::Scraper
  attr_writer :link

  def link_by(count)
    @url = "https://appropriations.house.gov/news?page=#{count}"
    result = connect_to(@url)
    if result.status != 200
      puts ('*'*200).green
      link_by(count)
    else
      return result.body
    end
  end
  
  def web_page
    web = "https://appropriations.house.gov#{@link}"
    result =  connect_to(web)
    if result.status != 200
      puts ('*'*200).green
      web_page
    else
      return result.body
    end
  end

  def clear
    time = Time.now.strftime("%Y_%m_%d").split('_').join('_')
    peon.give_list(subfolder: "press_releases").each do |file|
      peon.move(file: file, from: "press_releases", to: "trach_press_releases_#{time}")
    end
    peon.give_list(subfolder: "press_releases_index").each do |file|
      peon.move(file: file, from: "press_releases_index", to: "trach_press_releases_index_#{time}")
    end
  end
end
