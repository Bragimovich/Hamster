# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def link_by
    link = "https://sheriff.tazewell-il.gov/inmate-lookup-c/"
    @result = connect_to(link)
    @result.body
  end

  def clear
    time = Time.now.strftime("%Y_%m_%d").split('_').join('_')
    trash_folder = "Crime_perps_Illinois_#{time}"
    peon.list.each do |file|
      peon.move(file: file, to: trash_folder)
    end
  end
end
