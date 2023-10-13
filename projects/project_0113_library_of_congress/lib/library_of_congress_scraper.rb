require_relative '../models/loc'

class LibraryOfCongressScraper <  Hamster::Scraper

  MAIN_URL  = "https://www.loc.gov/news/?c=250&sp="

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_links = Loc.pluck(:link)
    @hash_array = []
  end

  def connect_to(url)
    retries = 0

    begin
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter )
      retries += 1
    end until response&.status == 200 or retries == 10

    document = Nokogiri::HTML(response.body)
  end

  def main_parser
    page_no = 1

    while true
      data_source_url = "#{MAIN_URL}#{page_no}"
      document = connect_to(data_source_url)
      current_page_links = document.css("span.item-description-title a").map{|e| e['href']}

      current_page_links.each_with_index do |link, ind|
        link = (link.include? " ") ? (link.split.join("%20") ): link
        next if @already_fetched_links.include? link
        article_data = connect_to(link)
        profile_links_parser(article_data , link , data_source_url)        
      end

      Loc.insert_all(@hash_array) if !@hash_array.empty?
      break if @hash_array.count < current_page_links.count
      @hash_array = []
      page_no += 1
    end
  end

  def profile_links_parser(document , link , data_source_url)
    document.css("h1 small").remove
    title = document.css("div.item-title h1").text.squish rescue nil
    subtitle = document.css("div.item-title h2").text.squish rescue nil
    contact_info = document.css("p.press-release-source")[0].to_s rescue nil
    article = articel_parsing(document)
    teaser = fetch_teaser(article)
    details_div = document.css("article.press-release-content").css("p")[-1]
    release_no , date , issn = fetch_details(details_div)
    data_hash = {}
    data_hash = {
      title: title,
      subtitle: subtitle,
      teaser: teaser,
      article: article.to_s,
      link: link,
      date: date,
      issn: issn,
      release_no: release_no,
      contact_info: contact_info,
      data_source_url: data_source_url
    }
    @hash_array << data_hash
  end

  def fetch_details(parsed_object)
    data_array = parsed_object.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>)/)
    release_no = data_array.select{|e| e[0].upcase.include? "PR"}.flatten.first.squish.split("PR").last.strip rescue nil
    date = Date.parse(data_array[-2][0].squish).to_date rescue nil
    issn = data_array.select{|e| e[0].upcase.include? "ISSN"}.flatten.first.squish.split("ISSN").last.strip rescue nil
    [release_no , date , issn]
  end

  def articel_parsing(document)
    document.css('img').remove
    document.css('iframe').remove
    document.css('figure').remove
    article = document.css("div#article") rescue nil
    article
  end

  def fetch_teaser(document)
    teaser = nil
     document.css('div#article div p').map do |node|
      next if node.text.squish == ""
      if (node.text.squish[-5..-1].include? "." or node.text.squish[3..-1].include? ":") and node.text.squish.length > 50
        teaser = node.text.squish
        break
      end
    end

    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = document.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
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
      ind = teaser.index dot[-1]
      teaser = teaser[0..ind].join(" ")      
    elsif teaser[-1] == ":" and !teaser.nil?
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
