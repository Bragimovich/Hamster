require_relative '../models/us_dept_agriculture'

class Scraper <  Hamster::Scraper

	SOURCE  = "https://www.usda.gov/media/press-releases?start_date=&page="
  MAIN_URL = "https://www.usda.gov"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_links =  UsDeptAgriculture.pluck(:link)
  end

  def connect_to(url)
    retries = 0

    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter )
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    document = Nokogiri::HTML(response.body)
  end

  def press_release_scraper
 	 	page_number = 0
    @flag = false
    while true
      puts "Processing Page No #{page_number}".yellow
      data_source_url = "#{SOURCE}#{page_number}"
      document = connect_to(data_source_url)
      press_release_parser(data_source_url, document)
      break if @flag == true
      page_number +=1
    end
  end

  def press_release_parser(data_source_url, document)
    press_release_data = []
    all_links = document.css('ul.news-releases li.news-releases-item a').map{|e| e["href"]}

    all_links.each_with_index do |article_link, ind|
  		article_link = "#{MAIN_URL}#{article_link}"
  		next if @already_fetched_links.include? article_link

  		date = Date.parse(document.css('div.news-release-date')[ind].text).to_date rescue nil
  		article = fetch_article(article_link)
  		title = @article_document.css('.usda-page-title').text.strip rescue nil
  		release_no = @article_document.css('.news-release-info div')[1].text.split('Release No.')[1].strip rescue nil
  		teaser = fetch_teaser(article)
  		contact_info = @article_document.css('.news-release-info p')

  		data_hash = {
      	title: title,
      	teaser: teaser,
      	article: article.to_s,
      	contact_info: contact_info.to_s,
      	release_no: release_no,
        date: date,
        link: article_link,
        data_source_url: data_source_url
      }
      press_release_data.push(data_hash)     
    end
    UsDeptAgriculture.insert_all(press_release_data) if !press_release_data.empty?
    @flag = true if press_release_data.count < all_links.count
  end

  def fetch_article(link)
    @article_document = connect_to(link)
    @article_document.css("img").remove
    @article_document.css("iframe").remove
    @article_document.css("figure").remove
    @article_document.css("script").remove
    article = @article_document.css('div#block-usda-content')[0]
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
      teaser = teaser.split('–', 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—', 2).last.strip
    elsif teaser[0..70].include? '─'
      teaser = teaser.split('─', 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--', 2).last.strip
    elsif teaser[0..50].include? ' - '
      teaser = teaser.split(' - ', 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
      teaser = teaser.split('-', 2).last.strip
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
