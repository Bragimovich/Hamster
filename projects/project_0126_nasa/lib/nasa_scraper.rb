require_relative '../models/nasa'

class NasaScrape <  Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_fetched_articles = Nasa.pluck(:data_source_url)
  end
  
  def connect_to(url)
    retries = 0

    begin
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter )
      retries += 1
    end until response&.status == 200 or retries == 10
    json_data = JSON.parse(response.body)
  end

  def get_url
    url = "https://www.nasa.gov/api/2/ubernode/_search?size=1&from=0&sort=promo-date-time%3Adesc&q=((ubernode-type%3Afeature%20OR%20ubernode-type%3Apress_release)%20AND%20(other-tags%3A5168))&_source_include=promo-date-time%2Cmaster-image%2Cnid%2Ctitle%2Ctopics%2Cmissions%2Ccollections%2Cother-tags%2Cubernode-type%2Cprimary-tag%2Csecondary-tag%2Ccardfeed-title%2Ctype%2Ccollection-asset-link%2Clink-or-attachment%2Cpr-leader-sentence%2Cimage-feature-caption%2Cattachments%2Curi"
    json_data = connect_to(url)
    total_articles = json_data["hits"]["total"]
    url = "https://www.nasa.gov/api/2/ubernode/_search?size=#{total_articles}&from=0&sort=promo-date-time%3Adesc&q=((ubernode-type%3Afeature%20OR%20ubernode-type%3Apress_release)%20AND%20(other-tags%3A5168))&_source_include=promo-date-time%2Cmaster-image%2Cnid%2Ctitle%2Ctopics%2Cmissions%2Ccollections%2Cother-tags%2Cubernode-type%2Cprimary-tag%2Csecondary-tag%2Ccardfeed-title%2Ctype%2Ccollection-asset-link%2Clink-or-attachment%2Cpr-leader-sentence%2Cimage-feature-caption%2Cattachments%2Curi"
  end

  def get_ids
    ids = []
    url = get_url
    json_data = connect_to(url)
    hits = json_data["hits"]["hits"]
    hits.each do |hit|
      ids << hit["_id"].to_i
    end
    ids
  end

  def main
    
    ids = get_ids()
    data_array = []
    ids.each do |id|
      data_source_url = "https://www.nasa.gov/api/2/ubernode/#{id}"
      next if @already_fetched_articles.include? data_source_url

      json_data = connect_to(data_source_url)
      title = json_data["_source"]["title"].strip rescue nil
      date_string = json_data["_source"]["changed"]
      date = Time.at(date_string.to_i).strftime('%a, %d %b %Y %H:%M:%S')
      article = json_data["_source"]["body"]
      article = article_cleaning(article)
      link = "https://www.nasa.gov" + json_data["_source"]["uri"].strip rescue nil
      release_no = json_data["_source"]["release-id"].strip rescue nil
      contact_info = json_data["_source"]["ubernode-pr-contacts"].strip rescue nil
      teaser = json_data["_source"]["pr-leader-sentence"].strip rescue nil

      data_hash = {
        title: title,
        date:  date,
        teaser: teaser,
        article: article,
        link: link,
        release_no: release_no,
        contact_info: contact_info,
        data_source_url: data_source_url,
      }
      data_array.push(data_hash)
    end
    Nasa.insert_all(data_array) if !data_array.empty?
  end

  def article_cleaning(article)
    article = Nokogiri::HTML(article)
    article.css("img").remove
    article.css("iframe").remove
    article.css("figure").remove
    article.css("video").remove
    article = article.to_s.gsub('</body></html>',"")
    article = article[120..-1]
    article
  end
end
