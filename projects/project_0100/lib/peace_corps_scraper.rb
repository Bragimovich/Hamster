require_relative '../models/peace_corps'

class PeaceCorpsScraper <  Hamster::Scraper

  MAIN_URL = "https://www.peacecorps.gov"

  def initialize
    super
    @filter = ProxyFilter.new(duration: 1.hours, touches: 500)
    @filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_articles = PeaceCorps.pluck(:link)
  end

  def scraper
    flag = false
    while true
      puts "Processing Page No 1".yellow
      data_source_url = "https://www.peacecorps.gov/news/library/?date__year=#{Date.today.year}"
      @document = request_method(data_source_url)
      flag = parser(data_source_url, flag)
      break if flag
    end
  end

  private

  def request_method(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter )
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    Nokogiri::HTML(response.body)
  end

  def fetch_teaser(parsed_object, date)
    teaser = '-'
    article = parsed_object
    article.css('p').map do |node|
      break if node.css("br").count > 3
      next if node.text.squish == ""
      if (node.text.squish[-3..-1].include? '.' or node.text.squish[-3..-1].include? ':') and node.text.squish.length > 50
        teaser = node.text.squish
        break
      end
    end

    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser == ""
        if (teaser[-3..-1].include? "." or teaser[-3..-1].include? ":") and teaser.length > 10
          break
        end
      end
    end

    if teaser.length > 600
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? "."}
      dot = dot.uniq
      ind = teaser.index dot[-1]
      teaser = teaser[0..ind].join(" ")
    end

    if teaser[-1].include? ":"
      teaser[-1] = "..."
    end
    if teaser[0..60].include? '–'
      teaser = teaser.split('–', 2).last.strip
    elsif teaser[0..60].include? '—'
      teaser = teaser.split('—', 2).last.strip
    elsif teaser[0..60].include? '--'
      teaser = teaser.split('--', 2).last.strip
    elsif teaser[0..60].include? ' - '
      teaser = teaser.split(' - ', 2).last.strip
    elsif teaser[0..60].include? "#{date}"
      teaser = teaser.split("#{date}", 2).last.squish
      teaser = teaser.split("#{date}", 2).last.squish if teaser[0..50].include? "#{date}"
      teaser = cleaning_teaser(teaser)
    elsif teaser[0..60].include? '-'
      teaser = teaser.split('-', 2).last.strip
    end

    teaser = nil if teaser == '-'
    if teaser[0..50].include? "#{Date.parse(date).year}" 
      teaser = teaser.split("#{Date.parse(date).year}", 2).last.strip
    end 
    teaser
  end

  def cleaning_teaser(teaser)
    if teaser[0..1].include? '–'
      teaser = teaser.split('–', 2).last.strip
    elsif teaser[0..1].include? '—'
      teaser = teaser.split('—', 2).last.strip
    elsif teaser[0..1].include? '--'
      teaser = teaser.split('--', 2).last.strip
    elsif teaser[0..1].include? '-'
      teaser = teaser.split('-', 2).last.strip
    end
    teaser
  end
  
  def parser(data_source_url, flag)
    hash_array = []
    all_links = @document.css("div.teaser.teaser--listing").map{|e| e.css("div.teaser__title a")[0]['href']}
    all_titles = @document.css("div.teaser.teaser--listing").map{|e| e.css("div.teaser__title a").text.squish}
    dates = @document.css("div.teaser__byline").map{|e| e.css("ul.ul--tags").text.squish.split[0..2].join(" ") }
    types = @document.css(".teaser__byline").map{|e| e.css("li").text}
    all_links.each_with_index do |link, ind|
      next if (types[ind] == "") || (types[ind] == "Newsletter")
      article_link = "#{MAIN_URL}#{link}"
      next if @already_fetched_articles.include? article_link
      article, teaser = fetch_article(article_link)
      data_hash = {}
      data_hash = {
        title: all_titles[ind],
        teaser: teaser,
        article: article,
        link: article_link,
        type: types[ind].downcase,
        date: dates[ind],
        data_source_url: data_source_url
      }
      hash_array.push(data_hash)
    end
    PeaceCorps.insert_all(hash_array) unless hash_array.empty?
    flag = true if hash_array.count < 10
    flag
  end

  def fetch_article(link)
    article_data = request_method(link)
    teaser = fetch_teaser(article_data.css("article div.layout-main-content")[0], article_data.css("p.dateline")[0].text.squish)
    article_data.css('img').remove
    article_data.css('iframe').remove
    article_data.css('div.story-info').remove
    article_data.css('figure').remove
    article_data.css('div.callout.callout--half-padding.callout--side-padding.callout--light-gray.is-spaced-below').remove
    article =  article_data.css("article div.layout-main-content")[0].to_s
    [article, teaser]
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
  end
end
