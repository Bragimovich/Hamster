require_relative '../models/us_dept_housing_and_urban_development'

class Scraper <  Hamster::Scraper

  BASE_URL = "https://www.hud.gov"
  SOURCE = "https://www.hud.gov/press/press_releases_media_advisories"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_articles = UsDept.pluck(:link)
    @press_release_data = []
  end
  
  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter )
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
  end

  def main
    links_array = []
    document = connect_to(SOURCE)
    document.css("div.field.field-name-body div.row p a").map{|e| links_array.push(BASE_URL + e.attr("href"))}
    links_array = links_array - @already_fetched_articles

    links_array.each do |link|
      next if link.include? ".pdf"
      next if @already_fetched_articles.include? link
      document = connect_to(link)
      parser(document,link)
    end

    UsDept.insert_all(@press_release_data) if !@press_release_data.empty?
    @press_release_data = []
  end 

  def parser(document, link)
    title = document.css("div.field-items h3 strong").text.strip  rescue nil
    begin
      release_no = document.css("div.field-items table").first.css("tr").first.css("td").first.text.split("\n").first
    rescue 
      release_no = document.css("span[itemprop='title']").last.text.strip
    end
    article = fetch_article(document)
    date,contact_info = fetch_date_contact(document,article)
    teaser = fetch_teaser(article)
    
    data_hash = {
      title: title,
      teaser: teaser,
      release_no: release_no,
      contact_info: contact_info,
      article: article.to_s,
      link: link,
      date: date,
      data_source_url: SOURCE,
    }
    @press_release_data.push(data_hash)
  end

  def fetch_date_contact(document,article)
    contact_info = document.css("div.field-items table").first.css("tr").first.css("td").first.children[1..-1].to_s rescue nil
    #date = Date.parse(document.css("div.field-items table").first.css("tr").first.css("td").last.children.last.text.squish) rescue nil
    #if date.nil?
      date = Date.parse(article.css("div.field-items table").first.css("tr").text.scan(/[A-Z]\w{2,}\W+\d{1,}\W+\d{4}/).first) rescue nil 
    #end
    [date,contact_info]
  end

  def fetch_article(document)
    article = document.css("div.field.field-name-body")
    article.css("img").remove
    article.css("iframe").remove
    article.css("figure").remove
    article.css("div#prfooter").remove
    article
  end 

  def fetch_teaser(article)
    teaser = nil
    article.css('p').map do |node|
      next if node.text.squish == ""
      if (node.text.squish[-3..-1].include? "." or node.text.squish[-3..-1].include? ":") and node.text.squish.length > 100
        teaser = node.text.squish
        break
      end
    end
    
    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish 
        next if teaser == ""
        if (teaser[-2..-1].include? "." or teaser[-2..-1].include? ":") and teaser.length > 10
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
    

    if teaser[-4..-1].include?(":") and !teaser.nil?
      teaser = teaser.split(":" , -2).first + "..."
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
    elsif teaser[0..30].include? '-'
      if teaser[0..30].include? "Washington" or teaser[0..30].include? "WASHINGTON"
      teaser = teaser.split('-' , 2).last.strip
      end
    end
    teaser
  end
end
