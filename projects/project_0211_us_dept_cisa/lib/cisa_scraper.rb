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
    #save_categories
  end


  def gathering(update = 0)
    page = 1

    peon = Peon.new(storehouse)
    file = "last_page"

    if "#{file}.gz".in? peon.give_list() and update == 0
      page, = peon.give(file:file).split(':').map { |i| i.to_i }
    end

    category_to_id = categories_db
    cobble = Dasher.new(:using=>:cobble)

    loop do
      p page
      url = "https://www.cisa.gov/newsroom"
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
          news.merge!(parse_one_news(news_html_page))
        # rescue
        #   next
        # end

        news[:md5_hash] = make_md5(news)

        add_categories_to_links(news, category_to_id)
        news.delete(:categories)
        add_tags(news)
        news.delete(:tags)

        news_to_db.push(news)
        q+=1
        #break if q>10
      end

      insert_to_db(news_to_db) if !news_to_db.empty?
      break
      break if news_to_db.length<10
      page +=1
      peon.put(content: "#{page}:", file: file)

    end
  end


  def save_categories
    url = "https://www.cisa.gov/newsroom"
    cobble = Dasher.new(:using=>:cobble)
    html = cobble.get(url)
    doc = Nokogiri::HTML(html)
    body = doc.xpath('//*[@id="block-views-block-publication-library-menu-block-3"]/div/div/div/div')

    categories = []
    body.css('li').each do |li|
      cat = li.css('a')[0]
      categories.push({
                        category: cat.content,
                        category_link: cat['href']
                      })
    end

    CisaCategories.insert_all(categories)

  end
end