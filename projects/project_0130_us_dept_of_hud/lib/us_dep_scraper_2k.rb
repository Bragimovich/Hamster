require_relative '../models/us_dept_housing_and_urban_development'

class UsDepScraper2k <  Hamster::Scraper

  MAIN_URL = "https://archives.hud.gov/news/index.cfm"
  SOURCE = "https://archives.hud.gov/news/"
  
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
   
    document = connect_to(MAIN_URL)
    all_year_links = []

    document.css("ul li a").map{|e| all_year_links << SOURCE + e["href"]}
    all_year_links = all_year_links.select{|e| e.split("/")[-1].split(".")[0].to_i < 2000 or e.split("/")[-1].split(".")[0].to_i == 2002}
    
    all_year_links.each do |year_link|
      document = connect_to(year_link)
      all_lis = document.css("ul")[0]
      all_lis.css("ul").remove
      all_lis = all_lis.css("li")
      all_lis.each do |li|
        date = fetch_date(li)
        title = li.text.strip.split(" ",2)[-1].split[0...-1].join(" ")
        release_no = "HUD No. " + li.text.strip.split[-1].gsub("(","").gsub(")","").strip
        link = SOURCE + li.css("a")[0]["href"]
        next if @already_fetched_articles.include? link
	next if link.include? ".pdf"
	next if link == "https://archives.hud.gov/news/1998/pr98-628a.html"
        document = connect_to(link)
        contact_info = document.css("table[bgcolor='CCCCCC']").css("tr")[1].css("td")[1].css("table")[0].css("td[align='LEFT']") rescue nil
        article = fetch_article(document)
        teaser = fetch_teaser(article)

        data_hash = {
          title: title,
          teaser: teaser,
          release_no: release_no,
          contact_info: contact_info.to_s,
          article: article.to_s,
          link: link,
          date: date,
          data_source_url: year_link,
        }
        @press_release_data.push(data_hash)
        if @press_release_data.count > 10
          UsDept.insert_all(@press_release_data) if !@press_release_data.empty?
          @press_release_data = []
        end
      end

      if @press_release_data.count > 0 # it should be here
        UsDept.insert_all(@press_release_data) if !@press_release_data.empty?
      end
    end
  end 

  def fetch_date(li)
    date_temp = li.text.strip.split[0].gsub(":","").strip
    date = nil
    if date_temp.split("/")[-1].length == 2
      date = DateTime.strptime(date_temp.split('/')[0...-1].join('/')+'/19'+date_temp.split('/')[-1], "%m/%d/%Y").to_date
    else
      date = DateTime.strptime(date_temp, "%m/%d/%Y").to_date
    end
    date
  end

  def fetch_article(document)
    article = document.css("table[bgcolor='CCCCCC']").first
    article.css("img").remove
    article.css("iframe").remove
    article.css("figure").remove
    article
  end
 


  def fetch_teaser(article)
    
    teaser = nil
    article.css('p').map do |node|
      next if node.text.squish == ""
      if (node.text.squish[-5..-1].include? "." or node.text.squish[3..-1].include? ":") and node.text.squish.length > 50
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
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
      teaser = teaser.split('-' , 2).last.strip
      end
    end
    teaser
  end
end
