require_relative '../models/us_cof_ranking_members_news'

class Scraper <  Hamster::Scraper

	SOURCE = 'https://www.finance.senate.gov/ranking-members-news?maxRows=999999&type=press_release'

	def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_links =  UsCofRankingMembersNews.pluck(:link)
  end

  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter )
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
  end

  def press_release_scraper
    data_source_url = "#{SOURCE}"
    document = connect_to(data_source_url)
    press_release_parser(data_source_url , document)
  end

  def press_release_parser(data_source_url , document)
    press_release_data = []
    all_links = document.css("table#browser_table tbody a").map{|e| e["href"].strip}
    all_links.each do |article_link|
      next if article_link.include? 'download'
      next if @already_fetched_links.include? article_link
      article = fetch_article(article_link)
      next if article.nil?
    	date = Date.parse(@article_document.css('.date')[0].text).to_date rescue nil
      with_table = 1 if @article_document.css('table').count > 0
      dirty_news = (@article_document.css("*").attr("lang").value.include? "en") ? 0 : 1
    	title = @article_document.css('.main_page_title')[0].text rescue nil
    	subtitle = @article_document.css('.subtitle')[0].text rescue nil
      teaser = fetch_teaser(article) rescue nil
    	data_hash = {
        	title: title,
        	subtitle: subtitle,
        	teaser: teaser,
        	article: article.to_s,
	        date: date,
          link: article_link,
	        with_table: with_table,
          dirty_news: dirty_news,
          data_source_url: data_source_url
      }
      press_release_data.push(data_hash)
      if press_release_data.count >= 25
        UsCofRankingMembersNews.insert_all(press_release_data)
        press_release_data = []
    	end
    end
    UsCofRankingMembersNews.insert_all(press_release_data) if !press_release_data.empty?
  end

  def fetch_article(link)
    @article_document = connect_to(link)
    @article_document.css("img").remove
    @article_document.css("iframe").remove
    @article_document.css("figure").remove
    @article_document.css("script").remove
    article = @article_document.css('div#pressrelease')[0]
    article
  end

	def fetch_teaser(data)
    teaser = nil
    article = data
    article.css("h2").remove
    article.css("h3").remove
    
    article.children.each do |node|
      next if node.text.squish == ""
      next if node.text.squish.length < 50
        if (node.text.squish[-10..-1].include? "." or node.text.squish[-10..-1].include? ":") and node.text.squish.length > 50
          teaser = node.text.squish
          break
        end
    end

    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish 
        next if teaser == ""
        if (teaser[-2..-1].include? "." or teaser[-2..-1].include? ":") and teaser.length > 100
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
    teaser = cleaning_teaser(teaser)
  end

  def cleaning_teaser(teaser)
    if teaser[0..50].include? '–'
      teaser = teaser.split('–' , 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—' , 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--' , 2).last.strip
    elsif teaser[0..50].include? ' - '
      teaser = teaser.split('-' , 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
      teaser = teaser.split('-' , 2).last.strip
      end
    end
    teaser
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
