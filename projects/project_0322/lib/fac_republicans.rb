# frozen_string_literal: true

require_relative '../models/us_dept_facr'

class FacRepublicans <  Hamster::Scraper

  MAIN_PAGE = "https://foreignaffairs.house.gov/press-release/"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed = FACR.pluck(:link)
    @data_array = []
  end

  def main
    page_no = 1
    data_source_url = MAIN_PAGE
    while true
      unless page_no == 1
        data_source_url = "#{MAIN_PAGE}page/#{page_no.to_s}/"
      end
      document,status = connect_to(data_source_url)
      releases = document.css(".content-container article")
      break if releases.empty?
      releases.each do |release|
        link = release.css("h1 a").first["href"]
        next if @already_processed.include? link
        document,status = connect_to(link)
        link_parser(document,release,data_source_url,link)
      end
      FACR.insert_all(@data_array) unless @data_array.empty?
      break if @data_array.count < releases.count
      @data_array = []
      page_no += 1
    end
  end

  private

  def link_parser(document,release,data_source_url,link)
    lang_tag = document.css("html").first["lang"]
    dirty_news = (document.css("html").first["lang"] == "en") ? 0 : 1
    date = release.css("time").first.text
    date = DateTime.strptime(date, "%m.%d.%y").to_date
    title = release.css("h1 a").text.squish
    article  = fetch_article(document)
    teaser = fetch_teaser(article,dirty_news)
    contact_info = document.css(".post-extra-info").first
    unless contact_info.nil?
      contact_info = contact_info.to_s
    end
    with_table = article.css("table").empty? ? 0 : 1

    data_hash = {
      title: title,
      teaser: teaser,
      article: article.to_s,
      link: link,
      date: date,
      with_table: with_table,
      dirty_news: dirty_news,
      contact_info: contact_info,
      data_source_url: data_source_url,
    }
    @data_array.push(data_hash)
  end

  def fetch_article(document)
    article = document.css("article.post").first
    remove_unnecessary_tags(article, %w[img iframe figure script])
    article
  end

  def remove_unnecessary_tags(doc, list)
    list.each { |tag| doc.css(tag).remove }
    doc
  end

  def fetch_teaser(article,dirty_news)
    teaser = nil
    return teaser if dirty_news == 1
    article = article.css('.post-content').first

    article.css("*").each do |node|
      next if node.text.squish == ""
      next if node.text.squish[-5..-1].nil?
      if node.text.squish.length > 100
        teaser = node.text.squish
        break
      end
    end
    
    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.css("*").to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      if data_array.empty?
        data_array.push(article.to_s)
      end
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish 
        next if teaser == ""
        next if teaser[-2..-1].nil?
        if teaser.length > 100
          break
        end
      end
    end

    teaser_temp = teaser
    if teaser.length > 600
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? "."}
      dot = dot.uniq
      ind = teaser.index dot[-1]
      teaser = teaser[0..ind].join(" ")
    end

    if teaser.length  < 80
      teaser = teaser_temp[0..600].split
      dot = teaser.select{|e| e.include? ":"}
      dot = dot.uniq
      ind = teaser.index dot[-1]
      teaser = teaser[0..ind].join(" ")
    end

    if teaser.length  < 20
      teaser = nil
      return teaser
    end

    if teaser[-1].include? ":"
      teaser[-1] = "..."
    end
    teaser = cleaning_teaser(teaser)
  end

  def cleaning_teaser(teaser)
    if teaser[0..50].include? '–'
      teaser = teaser.split('–', 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—', 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--', 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('‒', 2).last.strip
    elsif teaser[0..50].include? ' - '
      teaser = teaser.split('-', 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
      teaser = teaser.split('-', 2).last.strip
      end
    elsif teaser[0..18].upcase.include? 'WASHINGTON' and  teaser[0..10].include? '('
      teaser = teaser.split(')', 2).last.strip
    end
    teaser
  end

  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
    [document,response&.status]
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
