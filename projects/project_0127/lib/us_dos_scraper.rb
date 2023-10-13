require_relative '../models/us_dos'

class UsDeptOfState <  Hamster::Scraper

  MAIN_URL = "https://www.state.gov"
  URL = "https://www.state.gov/press-releases/"
  SOURCE = "https://www.state.gov/press-releases/page/"

  def initialize
    super
    @already_fetched_articles = UsDos.pluck(:link)
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url,headers: headers)
      retries += 1
    end until response&.status == 200 or response&.status == 301 or retries == 10
    document = Nokogiri::HTML(response.body)
    [document, response&.status]
  end

  def press_release_scraper
    page_number = 1
    @cron_break_flag = false
    while true
      page_number == 1 ? data_source_url = URL : data_source_url = "#{SOURCE}#{page_number}/"
      @document, code = connect_to(data_source_url)
      press_release_parser(data_source_url)
      break if @cron_break_flag
      page_number +=1
    end
  end

  def press_release_parser(data_source_url)
    press_release_data = []	
    all_links =  @document.css("ul#col_json_result li a").map{|e| e["href"]}

    all_links.each_with_index do |article_link, ind|
      next if @already_fetched_articles.include? article_link
      article = fetch_article(article_link)
      if article.nil?
        full_message = "Too Many 403 Requests. Check this project"
        Hamster.logger.error("Error: #{full_message}")
        Hamster.report(to: 'UD1LWNPEW', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{full_message}", use: :slack)
        @cron_break_flag = true
        return
      end
      date = @article_document.css("div.article-meta").css("p.article-meta__publish-date").text.strip
      creator = @article_document.css("div.article-meta")[0].css("p.article-meta__author-bureau")[0].text.strip rescue nil
      kind = @article_document.css("div.article-meta").css("p.article-meta.doctype-meta")[0].text.strip rescue nil
      data_hash = {
        title: @article_document.css("div.featured-content__copy h1").text.squish,
        teaser: fetch_teaser(article),
        article: article.to_s,
        link: article_link,
        creator: creator,
        kind: kind,
        country: fetch_country(),
        date:  Date.parse(date).to_date,
        data_source_url: URL,
      }
      press_release_data.push(data_hash)
    end
    UsDos.insert_all(press_release_data) if !press_release_data.empty?
    @cron_break_flag = true if press_release_data.count < all_links.count
  end

  def fetch_country
    a_links = @article_document.css("div.related-tags__pills a")
    country = nil

    a_links.each do |a|
      if a["href"].include?("/countries")
        country = a.text
        break
      end 
    end

    if country == nil
      country = a_links.select{|e| e["href"] == ""}[0].text.strip rescue nil
    end
    
    country
  end

  def fetch_article(link)
    code = 403
    wrong_counter = 0
    while code != 200
      return nil if wrong_counter == 30
      @article_document, code = connect_to(link)
      wrong_counter += 1
    end
    @article_document.css("img").remove
    @article_document.css("iframe").remove
    @article_document.css("figure").remove
    @article_document.css("script").remove
    
    article = @article_document.css("div.entry-content")[0]
    video = article.css("div")[0].css("video") rescue []
    if video != []
      article.css("div").first.remove
    end
    article
  end

  def fetch_teaser(article)
    teaser = nil

    article.children.map do |node|
      next if node.text.squish == ""
      next if node.text.squish[-3..-1].nil?
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
    
    if teaser.nil? or teaser == '' or teaser == '-'
      teaser = TeaserCorrector.new(article.text.squish).correct.strip
    else
      teaser = TeaserCorrector.new(teaser).correct.strip
    end
    cleaning_teaser(teaser)
  end

  def cleaning_teaser(teaser)
    if teaser[0..50].include? '–'
      teaser = teaser.split('–', 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—', 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--', 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
        teaser = teaser.split('-', 2).last.strip
      end
    end
    teaser
  end

  def headers
    {
      "Authority" => "www.state.gov",
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language" => "en-US,en;q=0.9",
      "Sec-Ch-Ua" => "\"Chromium\";v=\"110\", \"Not A(Brand\";v=\"24\", \"Google Chrome\";v=\"110\"",
      "Sec-Ch-Ua-Mobile" => "?0",
      "Sec-Ch-Ua-Platform" => "\"Linux\"",
      "Sec-Fetch-Dest" => "document",
      "Sec-Fetch-Mode" => "navigate",
      "Sec-Fetch-Site" => "none",
      "Sec-Fetch-User" => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36"
    }
  end
end
