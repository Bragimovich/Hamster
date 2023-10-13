# frozen_string_literal: true

require_relative '../models/us_bor'

class Scraper <  Hamster::Scraper

  URL = "https://www.usbr.gov/newsroom/apinewsroom/?format=json&pager_length=10000&type=news_release&from=2001-01-01&to=#{Date.today.to_s}&null=&start_pager=0"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @already_processed = Bor.pluck(:link)
  end

  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter , open_timeout: 320)
      retries += 1
    end until response&.status == 200 or retries == 15
    document = JSON.parse(response.body)
  end

  def scraper
    document = connect_to(URL)
    parser(document)
  end

  def parser(body)
    array = []
    body.each do |content|
      link = "https://www.usbr.gov/newsroom/#/news-release/#{content["id"]}"
      p link
      next if @already_processed.include? link
      title = content["content"]["title"].squish
      subtitle = content["content"]["field_sub_headline"].squish
      article = Nokogiri::HTML(content["content"]["body"]).css("body")
      teaser = content["content"]["body_summary"].squish
      teaser = fetch_teaser(article) if teaser == "" or teaser.nil?
      article.css("img").remove
      article.css("figure").remove
      date = Date.parse(content["content"]["field_date_to_be_published"].split.first) rescue nil
      with_table = article.css("table").empty? ? 0 : 1
      contact_info = get_contact_info(content["content"])
      type = content["type"]
      article = article.css("body")
      data_hash = {
        title: title,
        subtitle: subtitle,
        teaser: teaser,
        article: article.to_s,
        date: date,
        link: link,
        type: type,
        contact_info: contact_info,
        with_table: with_table
      }
      array.push(data_hash)
    end
    Bor.insert_all(array) if !array.empty?
  end

  def get_contact_info(content)
    contact_info = nil
    contact_info = "<div class='small-header'><span>Media Contact: </span>
            #{[content["field_primary_contact_name"] ,  content["field_primary_contact_phone"] , content["field_primary_contact_email"]].join(" ").strip}
         </div>"
    second_contact = [content["field_secondary_contact_name"] ,  content["field_secondary_contact_phone"] , content["field_secondary_contact_email"]].join(" ").strip
    if second_contact != ""
      secondary_contact = "<div class='small-header'> #{second_contact} </div>"
      contact_info = [contact_info, secondary_contact].join(" ")
    end
    contact_info
  end

  def fetch_teaser(article)
    teaser = nil
    article.children.each do |node|
      next if node.text.squish == "" or node.text.squish.length < 50
        if (node.text.squish[-5..-1].include? "." or node.text.squish[-5..-1].include? ":") and node.text.squish.length > 50
          teaser = node.text.squish
          break
        end
    end
    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser == "" or teaser.length < 100
        if (teaser[-5..-1].include? "." or teaser[-5..-1].include? ":") and teaser.length > 100
          break
        end
      end
    end
    return nil if teaser.nil? or teaser == ""
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
