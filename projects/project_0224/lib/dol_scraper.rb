# frozen_string_literal: true

require_relative '../models/us_dol_osha'

class DolScraper < Hamster::Scraper

  MAIN_URL  = 'https://www.osha.gov/news/newsreleases/infodate-y/'
  DOMAIN    = 'https://www.osha.gov'
  MONTH_URL = 'https://www.osha.gov/news/newsreleases'
  
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @already_fetched_articles = UsDol.pluck(:link)
    @data_array = []
  end

  def main
    year =  Date.today.year
    while true
      data_source_url = MAIN_URL + year.to_s
      document = connect_to(data_source_url)
      months = document.css('ul.views-summary li a')
      break if months.empty?

      month_links = months.map { |e| MONTH_URL + e["href"].strip.gsub('..', '') }
      month_links.each do |month_link|
        document = connect_to(month_link)
        inner_links = document.css('.view-content ul li a').map { |e| DOMAIN + e["href"].strip }
        inner_links.each do |link|
          next if @already_fetched_articles.include? link

          15.times do
            document = connect_to(link)
            break if is_fully_loaded(document)
          end
          year < 2015 ? inner_page_parser_before_2015(document, link, data_source_url) : inner_page_parser(document, link, data_source_url)
          if @data_array.count > 20
            UsDol.insert_all(@data_array) if !@data_array.empty?
            @data_array = []
          end
        end
        UsDol.insert_all(@data_array) unless @data_array.empty?
      end
      year += 1
    end
    UsDol.insert_all(@data_array) unless @data_array.empty?
  end

  private

  def is_fully_loaded(document)
    article = document.css('div.field.field--name-field-press-body').first rescue nil
    return false if article.nil?
    true
  end

  def inner_page_parser(document, link, data_source_url)
    if document.css("*[lang]").first["lang"] != 'en'
      article = fetch_article(document)
      data_hash = dirty_news_hash(article, link, data_source_url)
      @data_array.push(data_hash)
      return
    end
    article = fetch_article(document)
    date_string = article.text.scan(/[A-Z]*[a-z]+\.*\s+\d{1,2},*\s+\d{4}/).first.gsub('Di', 'De') rescue nil
    date = Date.parse(date_string).to_date rescue nil
    subtitle, title = find_title(article, document)
    contact_info = fetch_contact(article)
    release_no = fetch_release(article)
    with_table = article.css('table').empty? ? 0 : 1
    teaser = fetch_teaser(article)
    data_array = [title, subtitle, teaser, contact_info, article, link, date, release_no, data_source_url, with_table]
    data_hash = create_data_hash(data_array)
    @data_array.push(data_hash)
  end

  def find_title(article, document)
    title_class = article.css("p[class*='center']",  "p[align='center']", "p[style*='center']").first
    subtitle    = title_class.css('em').first.text.strip.squish rescue nil
    title_class.css('em').remove unless title_class.nil?
    title = title_class.text.strip.squish rescue nil
    title = document.css('div.paragraph h4').text.squish if title.nil? || title.empty? || (title.include? '# #')
    title = document.css('div.field--name-field-press-body strong')[0].text if title.nil? || title.empty? || (title.include? '# #') rescue nil
    title = document.css('div.field--name-field-press-body b')[0].text if title.nil? || title.empty? || (title.include? '# #') rescue nil
    [subtitle, title]
  end

  def inner_page_parser_before_2015(document, link, data_source_url)
    if document.css('*[lang]').select { |e| e["lang"] != 'en' }.count != 0
      article   = fetch_article(document)
      data_hash = dirty_news_hash(article, link, data_source_url)
      @data_array.push(data_hash)
      return
    end
    
    article     = fetch_article(document)
    date_string = article.text.scan(/[A-Z]*[a-z]+\.*\s+\d{1,2},*\s+\d{4}/).first
    date        = Date.parse(date_string).to_date
    title_class = article.css("p[align='center']").first
    subtitle    = title_class.css('em').first.text.strip.squish rescue nil
    title_class.css('em').remove
    title  = title_class.text.strip.squish
    teaser = fetch_teaser(article)
    article_for_contct = article
    article_for_contct.css("p[align='center']").remove
    contact_info = article_for_contct.css('p.blackBoldTen', 'p.blackTen').first.to_s rescue nil
    release_no   = nil
    unless contact_info.nil?
      release = article_for_contct.css('p.blackBoldTen', 'p.blackTen').first
      release.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/).each do |node|
        if node[0].include? 'Release'
          release_no = node[0].split(':').last.strip.squish
          break
        end
      end
    end
    with_table = article.css('table').empty? ? 0 : 1
    data_array = [title, subtitle, teaser, contact_info, article, link, date, release_no, data_source_url, with_table]
    data_hash  = create_data_hash(data_array)
    @data_array.push(data_hash)
  end

  def fetch_contact(article)
    contact_info = nil
    flag = false
    article.css('p').each do |element|
      if flag
        contact_info += element.to_s
        break
      end
      if element.text.include? 'Media Contact'
        contact_info = element.to_s
        flag = true
      end
    end
    if contact_info.nil? 
      article.css("p").each do |element|
        break if article.css("p[class*='center']").first == element

        if element.text.include? 'Contact'
          contact_info = element.to_s
          break
        end
      end
    end
    unless contact_info.nil?
      contact_info = (contact_info.include? 'Contact') ? contact_info.split(':')[1..].join(':').insert(0, '<p>') : contact_info
      contact_info = (contact_info.include? 'Release Number') ? contact_info.split('Release Number')[0] + '</p>' : contact_info rescue nil
    end
    contact_info
  end

  def fetch_release(article)
    release_no = nil
    article.css('p').each do |element|
      if element.text.include? 'Release Number'
        release_no = element.text.split('Release Number')[1].gsub(':','').strip.squish
        break
      end
    end
    release_no
  end

  def fetch_article(document)
    article = document.css('div.field.field--name-field-press-body').first rescue nil
    article.css('img').remove
    article.css('iframe').remove
    article.css('figure').remove
    article.css('script').remove
    article
  end
 
  def fetch_teaser(article)
    teaser = nil
    article.css('h2').remove
    article.css('h3').remove
    article.css('h1').remove
    article.css('script').remove
    article.css("p[class*='center']").remove
  
    article.children.each do |node|
      next if node.text.squish.empty? or node.text.squish[-5..].nil?

      if (node.text.squish[-5..].include? '.' or node.text.squish[-5..].include? ':') and node.text.squish.length > 100
        teaser = node.text.squish
        break

      end
    end
    if teaser == '-' or teaser.nil? or teaser.empty?
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser.empty? or teaser[-2..].nil?

        if (teaser[-2..].include? '.' or teaser[-2..].include? ':') and teaser.length > 100
          break
        end
      end
    end
    
    if teaser.length > 600
      teaser = teaser[0..600].split
      dot    = teaser.select{|e| e.include? '.'}.uniq
      ind    = teaser.index dot[-1]
      teaser = teaser[0..ind].join(' ')
    end

    (teaser[-1].include? ':')? teaser[-1] = '...' : teaser
    cleaning_teaser(teaser)
  end

  def cleaning_teaser(teaser)
    if teaser[0..50].include? '–'
      teaser = teaser.split('–', 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—', 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--', 2).last.strip
    elsif teaser[0..50].include? ' - '
      teaser = teaser.split('-', 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? 'Washington' or teaser[0..50].include? 'WASHINGTON'
      teaser = teaser.split('-', 2).last.strip
      end
    elsif teaser[0..18].upcase.include? 'WASHINGTON' and teaser[0..10].include? '('
      teaser = teaser.split(')', 2).last.strip
    end
    teaser
  end

  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter )
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    Nokogiri::HTML(response.body.force_encoding('utf-8'))
  end

  def dirty_news_hash(article, link, data_source_url)
    {
      title: nil,
      subtitle: nil,
      teaser: nil,
      contact_info: nil,
      article: article.to_s,
      link: link,
      date: nil,
      release_no: nil,
      data_source_url: data_source_url,
      with_table: nil,
      dirty_news: 1
    }
  end

  def create_data_hash(data_array)
    {
      title: data_array[0],
      subtitle: data_array[1],
      teaser: data_array[2],
      contact_info: data_array[3],
      article: data_array[4].to_s,
      link: data_array[5],
      date: data_array[6],
      release_no: data_array[7],
      data_source_url: data_array[8],
      with_table: data_array.last,
      dirty_news: 0
    }
  end

  def reporting_request(response)
    # unless @silence
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
    # end
  end
end
