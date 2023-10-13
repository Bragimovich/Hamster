# frozen_string_literal: true

require_relative '../models/us_dept_census'

class CensusBureau <  Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed = Census.pluck(:link)
    @data_array = []
  end

  def main
    records_count = 0
    break_flag = false
    while true
      response = fetch_outer_page(records_count)
      data     = JSON.parse(response.body)
      records  = data["documents"]
      records.each do |record|
        link = record["docUrl"]
        next if @already_processed.include? link

        response = connect_to(link)
        document = Nokogiri::HTML(response.body)
        inner_page_parser(document, link, record)
      end
      Census.insert_all(@data_array) unless @data_array.empty?
      break if @data_array.count < records.count

      @data_array = []
      records_count += 36
    end
  end

  private

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter ,open_timeout: 30)
      retries += 1
    end until response&.status == 200 or retries == 10
    response
  end

  def fetch_outer_page(count)
    url = "https://www.census.gov/bin/faceted/getfacets"
    headers = { "content-type" => "\"application/json;\"" }
    form_body = JSON.dump({"baseTags":["Census:Type/Media-Resource/local-area-pr","Census:Type/Media-Resource/press-release"],"documentPath":"/content/census/en/newsroom/press-releases","matchType":"any","programs":[],"topics":[],"years":[],"geographies":[],"authors":[],"startRow":count,"sortBy":["DATE_DESCENDING","DATE_DESCENDING"]})
    Hamster.connect_to(url: url, req_body: form_body, proxy_filter: @proxy_filter, headers: headers, method: :post)
  end

  def inner_page_parser(document, link, record)
    lang_tag     = document.css("html").first["lang"]
    dirty_news   = 0
    dirty_news   = 1 if !(lang_tag.nil?) and lang_tag != "en"
    title        = record["docTitle"]
    date         = record["docDispalyPubDate"]&.to_date
    release_no   = record["documentNumber"]
    article      = fetch_article(document)
    contact_info = document.css("div.contactinfo")&.first.to_s
    contact_info = document.css("div.uscb-contact-info-contact-data").first.to_s if contact_info.empty?
    connect_info = nil if contact_info.empty?
    teaser       = fetch_teaser(article, dirty_news)
    with_table   = article.css("table").empty? ? 0 : 1
    data_hash = {
      title: title,
      teaser: teaser,
      contact_info: contact_info,
      article: article.to_s,
      link: link,
      date: date,
      release_no: release_no,
      with_table: with_table,
      dirty_news: dirty_news,
    }
    @data_array.push(data_hash)
  end   

  def fetch_article(document)
    article = document.css("div.uscb-main-responsivegrid")
    return document.css("body").first  if article.nil?
    article.css("img").remove
    article.css("iframe").remove
    article.css("figure").remove
    article.css("script").remove
    article.css("b").remove
    article
  end

  def fetch_teaser(article, dirty_news)
    teaser = nil
    if dirty_news == 1
      return teaser
    end
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
    if teaser.length > 600
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? "."}
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
      teaser = teaser.split('–' , 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—' , 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--' , 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('‒' , 2).last.strip
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
