# frozen_string_literal: true
require_relative '../models/baltfe'

class Scraper <  Hamster::Scraper

	MAIN_URL = 'https://www.atf.gov'
  SOURCE = 'https://www.atf.gov/news/press-releases?page='

	def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_links =  Baltfe.pluck(:link)
  end

  def connect_to(url)
    retries = 0

    begin
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter )
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
  end

  def press_release_scraper
    @flag = false
    page_number = 0
    while true
      data_source_url = "#{SOURCE}#{page_number}"
      @document = connect_to(data_source_url)
      press_release_parser
      break if @flag
      page_number +=1
    end
  end

  def press_release_parser
    press_release_data = []
    all_links =  @document.css(".view-content")[0].css('.field-content a').map{|e| e['href']}
    all_links.each do |article_link|
    	article_link = "#{MAIN_URL}#{article_link}"
    	next if @already_fetched_links.include? article_link
    	article = fetch_article(article_link)
    	date = Date.parse(@article_document.css('.date-display-single')[0].text).to_date rescue nil
    	title = @article_document.css('.press-release--titles')[0].css('h3').text.strip rescue nil
    	subtitle = @article_document.css('.press-release--titles')[0].css('.field--name-field-subtitle').text.strip rescue nil
      subtitle = nil if subtitle == ""
    	contact_info = @article_document.css('.press-release--contact') rescue nil
      dirty_news = (@article_document.css("*").attr("lang").value.include? "en") ? 0 : 1
      with_table = @article_document.css("table").empty? ? 0 : 1
      teaser = fetch_teaser(article.css('.field__item')[0])
      bureau_office = @article_document.css('header')[1].text.strip.squish rescue nil

    	data_hash = {
      	title: title,
      	subtitle: subtitle,
      	teaser: teaser,
      	article: article.to_s,
        date: date,
        contact_info: contact_info.to_s,
        link: article_link,
        dirty_news: dirty_news,
        with_table: with_table,
        bureau_office: bureau_office
      }
      press_release_data.push(data_hash)
    end
    Baltfe.insert_all(press_release_data) if !press_release_data.empty?
    @flag = true if all_links.count > press_release_data.count
  end

  def fetch_article(link)
    @article_document = connect_to(link)
    @article_document.css("img").remove
    @article_document.css("iframe").remove
    @article_document.css("figure").remove
    @article_document.css("script").remove
    article = @article_document.css('.node__content .field--name-body.field--type-text-with-summary')[0]
    article
  end

  def fetch_teaser(data)
    teaser = nil
    article = data.clone
    article.css("h2").remove
    article.css("h3").remove
    
    article.css('*').each do |node|
      next if node.text.squish == ""
      next if node.text.squish.length < 50
        if (node.text.squish[-3..-1].include? "." or node.text.squish[-3..-1].include? ":") and node.text.squish.length > 50 
          teaser = node.text.squish
          break
        end
    end
    
    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish 
        next if teaser == ""
        next if teaser.length < 50
        if (teaser[-2..-1].include? "." or teaser[-2..-1].include? ":") and teaser.length > 50
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
end
