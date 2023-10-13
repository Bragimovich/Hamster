# frozen_string_literal: true

require 'socksify'

class Scraper <  ConnectTo
  attr_writer :link

  def link_by(count)
    url   = "https://freddiemac.gcs-web.com/?page=#{count}"
    connect(url: url)
  end

  def web_page
    web = "https://freddiemac.gcs-web.com/#{@link}"
    connect(url: web)
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
