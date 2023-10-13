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

  def initialize(update=0, type)
    super
    gathering(update, type)

  end

  def blank_url_choose(type)
    case type
    when :d
      "https://www.energy.senate.gov/democratic-news?page="
    when :r
      "https://www.energy.senate.gov/republican-news?page="
    end
  end


  def gathering(update = 0, type=nil)
    type = :d if type==nil
    type = type.to_sym
    page = 1

    peon = Peon.new(storehouse)
    file = "#{type}_last_page"

    if "#{file}.gz".in? peon.give_list() and update == 0
      page, = peon.give(file:file).split(':').map { |i| i.to_i }
    end

    blank_url = blank_url_choose(type)
    cobble = Dasher.new(:using=>:cobble)

    loop do
      p page
      url = blank_url + page.to_s
      list_news_html_page = cobble.get(url)

      list_news = parse_list_news(list_news_html_page)


      news_links = list_news.map { |q| q[:link] }
      existing_links = get_existing_links(news_links, type) #check exists
      news_to_db = []

      list_news.each do |news|
        next if news[:link].in? existing_links

        news_html_page = cobble.get(news[:link])
        begin
          news.merge!(parse_one_news(news_html_page))
        rescue
          next
        end

        news[:md5_hash] = make_md5(news)

        news_to_db.push(news)
      end

      insert_to_db(news_to_db, type) if !news_to_db.empty?
      break if list_news.length<10
      break if news_to_db.length<10 and update==1
      page +=1
      peon.put(content: "#{page}:", file: file)

    end
  end
end