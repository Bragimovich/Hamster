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
    gathering(update)

  end


  def gathering(update = 0, type=nil)
    type = :news if type==nil
    type = type.to_sym
    page = 1

    peon = Peon.new(storehouse)
    file = "#{type}_last_page"

    if "#{file}.gz".in? peon.give_list() and update == 0
      page, = peon.give(file:file).split(':').map { |i| i.to_i }
    end


    cobble = Dasher.new(:using=>:cobble)

    loop do
      url = "https://republicans-homeland.house.gov/committee-activity/press-releases/"
      list_news_html_page = cobble.get(url)

      list_news = parse_list_news(list_news_html_page)

      news_links = list_news.map { |q| q[:link] }
      existing_links = get_existing_links(news_links) #check exists
      news_to_db = []
      q = 0
      list_news.each do |news|
        next if news[:link].in? existing_links

        news_html_page = cobble.get(news[:link])
        #begin
          news.merge!(parse_one_news(news_html_page, news[:title]))
        # rescue
        #   next
        # end

        news[:md5_hash] = make_md5(news)
        news_to_db.push(news)
        q+=1
        break if q>100
      end

      insert_to_db(news_to_db) if !news_to_db.empty?
      break if news_to_db.length<100

    end
  end
end