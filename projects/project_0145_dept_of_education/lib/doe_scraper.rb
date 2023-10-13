# frozen_string_literal: true

def make_md5(news_hash)
  all_values_str = ''
  columns = %i[title link date]
  columns.each do |key|
    if news_hash[key].nil?
      all_values_str = all_values_str + news_hash[key.to_s].to_s
    else
      all_values_str = all_values_str + news_hash[key].to_s
    end
  end
  Digest::MD5.hexdigest all_values_str
end



class Scraper < Hamster::Scraper

  def initialize(update=0)
    super
    gathering(update)
  end

  def gathering(update=0)
    releases_on_page = 10

    page = 0
    peon = Peon.new(storehouse)
    dasher = Dasher.new(:using=>:cobble)
    loop do
      url_main = "https://www.ed.gov/news/press-releases?page=#{page}"
      page_list_press_releases = dasher.get(url_main)

      general_press_releases = parse_list_releases(page_list_press_releases)
      peon.put content:page_list_press_releases, file: "page#{page}"
      new_links = general_press_releases.map { |row| "https://www.ed.gov"+row[:link] }
      #p new_links
      existing_links_array = existing_links(new_links)
      full_press_releases = []
      general_press_releases.each do |press_release_general|
        press_release_general[:link] = "https://www.ed.gov" + press_release_general[:link]
        next if press_release_general[:link].in? existing_links_array
        press_release_general[:md5_hash] = make_md5(press_release_general)

        page_press_release = dasher.get(press_release_general[:link])
        filename = press_release_general[:link].split('/')[-1].gsub(/['"”%#\*]/, '')

        peon.put content:page_press_release, file: filename #https://www.ed.gov/news/press-releases/

        other_release = parse_release(page_press_release)

        full_press_releases.push(press_release_general.merge(other_release))
      end
      insert_all full_press_releases
      break if general_press_releases.length < releases_on_page
      break if full_press_releases.length < releases_on_page && update==1
      page+=1
    end

  end

end