# frozen_string_literal: true

require_relative '../models/us_ncua'
require_relative '../models/us_ncua_categories'
require_relative '../models/us_ncua_categories_article'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class Scraper <  Hamster::Scraper

  MAIN_URL = "https://www.ncua.gov/news/press-releases?page=0&sort=date&dir=desc&npp=100&sq=#results"
  BASE_URL = "https://ncua.gov"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_articles = UsNcua.pluck(:link)
  end

  def main    
    @flag = false
    page = 0
    category_id_hash = UsNcuaCategories.pluck(:category,:id).to_h
    while true
      data_source_url = "#{BASE_URL}/news/press-releases?page=#{page}&sort=date&dir=desc&npp=100&sq=#results"
      document = outer_page_response
      document =  Nokogiri::HTML(outer_page_response.body)
      current_page_parser(data_source_url, document, category_id_hash)
      break if @flag == true
      page += 1
    end
    insert_link_cat_ids
  end

  def current_page_parser(data_source_url, document, category_id_hash)
    press_release_data = []
    current_page_releases = document.css("table#edit-searchresults tbody tr")
    current_page_releases.each do |release|
      link = BASE_URL + release.css("a")[0]["href"]
      next if @already_fetched_articles.include? link
      categorie_id = category_id_hash[release.css("td")[1].text.strip]
      date = DateTime.strptime(release.css("td")[2].text.strip, "%m/%d/%Y").to_date
      title = release.css("a")[0].text.strip
      inner_page = inner_page_request(link)
      document =  Nokogiri::HTML(inner_page.body)
      subtitle = document.css("#block-main-content div.body.field-type-text_with_summary").first.css("h2").first.text.squish rescue nil
      if subtitle.nil? or subtitle == ""
        subtitle = document.css("#block-main-content div.body.field-type-text_with_summary").first.css("h4").first.text.squish rescue nil
      end
      contact_info = document.css("div#block-mediainquiries").to_s rescue nil
      article = fetch_article(document)
      teaser = fetch_teaser(article)

      data_hash = {
        title: title,
        us_ncua_categorie_id: categorie_id,
        subtitle: subtitle,
        teaser: teaser,
        contact_info: contact_info,
        article: article.to_s,
        link: link,
        date: date,
        data_source_url: data_source_url,
      }
      press_release_data.push(data_hash)
    end
    UsNcua.insert_all(press_release_data) if !press_release_data.empty?
    @flag = true if press_release_data.count != current_page_releases.count
  end

  def fetch_article(document)
    article = document.css("#block-main-content div.body.field-type-text_with_summary").first
    article.css("img").remove
    article.css("iframe").remove
    article.css("figure").remove
    article
  end
 
  def fetch_teaser(data)
    teaser = nil
    article = data
    article.css("h2").remove
    article.css("h3").remove
    article.children.each do |node|
      next if node.text.squish == ""
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

  def insert_categories
    connection = categories_request
    document = Nokogiri::HTML(connection.body)
    categories = document.css("#edit-f-subject option").map{|e| e.text.strip}[2..-1]
    db_categories = UsNcuaCategories.pluck(:category)
    categories = categories - db_categories
    if !categories.empty?
      categories_data = []
      categories.each do |cat|
        data_hash = {
          category: cat,
        }
        categories_data.push(data_hash)
      end
      UsNcuaCategories.insert_all(categories_data)
    end
  end

  def categories_request(retries = 50)
    begin
      uri = URI.parse("https://ncua.gov/news/press-releases?page=0&sort=date&dir=desc&npp=100&sq=")
      request = Net::HTTP::Get.new(uri)
      request["Authority"] = "ncua.gov"
      request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
      request["Accept-Language"] = "en-US,en;q=0.9"
      request["Sec-Ch-Ua"] = "\"Google Chrome\";v=\"111\", \"Not(A:Brand\";v=\"8\", \"Chromium\";v=\"111\""
      request["Sec-Ch-Ua-Mobile"] = "?0"
      request["Sec-Ch-Ua-Platform"] = "\"Linux\""
      request["Sec-Fetch-Dest"] = "document"
      request["Sec-Fetch-Mode"] = "navigate"
      request["Sec-Fetch-Site"] = "none"
      request["Sec-Fetch-User"] = "?1"
      request["Upgrade-Insecure-Requests"] = "1"
      request["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      proxy_ip, proxy_port = get_proxy
      response = Net::HTTP.SOCKSProxy(proxy_ip, proxy_port).start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    rescue StandardError => e
      raise if retries <= 1
      categories_request(retries - 1)
    end
  end

  def insert_link_cat_ids
    link_cat_ids = UsNcua.pluck(:id,:us_ncua_categorie_id)
    db_link_cat_ids = UsNcuaCategoriesArticle.pluck(:article_link_id,:us_ncua_categorie_id)
    link_cat_ids = link_cat_ids - db_link_cat_ids
    if !link_cat_ids.empty?
      link_cat_data = []
      link_cat_ids.each do |ids|
        data_hash = {
          article_link_id: ids[0],
          us_ncua_categorie_id: ids[1],
        }
        link_cat_data.push(data_hash)
      end
      UsNcuaCategoriesArticle.insert_all(link_cat_data)
    end
  end

  def outer_page_response(retries = 50)
    begin
      uri = URI.parse("https://ncua.gov/news/press-releases?page=0&sort=date&dir=desc&npp=100&sq=")
      request = Net::HTTP::Get.new(uri)
      request["Authority"] = "ncua.gov"
      request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
      request["Accept-Language"] = "en-US,en;q=0.9"
      request["Sec-Ch-Ua"] = "\"Google Chrome\";v=\"111\", \"Not(A:Brand\";v=\"8\", \"Chromium\";v=\"111\""
      request["Sec-Ch-Ua-Mobile"] = "?0"
      request["Sec-Ch-Ua-Platform"] = "\"Linux\""
      request["Sec-Fetch-Dest"] = "document"
      request["Sec-Fetch-Mode"] = "navigate"
      request["Sec-Fetch-Site"] = "none"
      request["Sec-Fetch-User"] = "?1"
      request["Upgrade-Insecure-Requests"] = "1"
      request["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      proxy_ip, proxy_port = get_proxy
      response = Net::HTTP.SOCKSProxy(proxy_ip, proxy_port).start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    rescue StandardError => e
      raise if retries <= 1
      outer_page_response(retries - 1)
    end
  end

  def inner_page_request(link, retries = 50)
    begin
      uri = URI.parse(link)
      request = Net::HTTP::Get.new(uri)
      request["Authority"] = "ncua.gov"
      request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
      request["Accept-Language"] = "en-US,en;q=0.9"
      request["Sec-Ch-Ua"] = "\"Google Chrome\";v=\"111\", \"Not(A:Brand\";v=\"8\", \"Chromium\";v=\"111\""
      request["Sec-Ch-Ua-Mobile"] = "?0"
      request["Sec-Ch-Ua-Platform"] = "\"Linux\""
      request["Sec-Fetch-Dest"] = "document"
      request["Sec-Fetch-Mode"] = "navigate"
      request["Sec-Fetch-Site"] = "none"
      request["Sec-Fetch-User"] = "?1"
      request["Upgrade-Insecure-Requests"] = "1"
      request["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      proxy_ip, proxy_port = get_proxy
      response = Net::HTTP.SOCKSProxy(proxy_ip, proxy_port).start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    rescue StandardError => e
      raise if retries <= 1
      inner_page_request(link, retries - 1)
    end
  end

  def get_proxy
    proxy_record = PaidProxy.all.to_a.shuffle.first
    proxy_ip = proxy_record['ip']
    proxy_port = proxy_record['port']
    [proxy_ip, proxy_port]
  end

end
