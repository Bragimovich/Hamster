# frozen_string_literal: true

def parse_list_teasers(html)
  doc = Nokogiri::HTML(html)
  array_teasers = []
  html_list_title = doc.xpath('//header[@class="post-header"]//a')
  html_list_date = doc.xpath('//header[@class="post-header"]//span[@class="event-time"]')
  html_list_teaser = doc.xpath('//article[@class="post"]/p')
  html_list_link = doc.xpath('//header[@class="post-header"]//a').map { |link| link['href'] }
  for i in 0..html_list_title.length - 1 do
    array_teasers.push({})
    array_teasers[-1][:link]   = html_list_link[i]
    array_teasers[-1][:title]  = html_list_title[i].text.gsub("🚨", "")
    array_teasers[-1][:teaser] = html_list_teaser[i].text
  end
  array_teasers
end

def parse_article(html, url_main)
  page       = Nokogiri::HTML(html)
  article    = page.xpath('//section[@class="col-sm-12 main-feed single-post-content"]') rescue nil
  subtitle   = page.css('div.subheading').text rescue nil
  date       = page.css('span.date')[0].text.squish.split("—")[0].to_date rescue nil
  with_table = (article[0].include?('<table') unless article[0].nil?) ? 1 : 0
  dirty_news = (page.css('*').attr("lang").value.include? 'en' unless (page.css('*').attr("lang")).nil?) ? 0 : 1
  data = {
    "article": article.to_s.gsub("🚨", ""),
    "with_table": with_table,
    "dirty_news": dirty_news,
    "subtitle": subtitle,
    "date": date,
    "data_source_url": 'https://waysandmeans.house.gov/category/press-releases/'
  }
  data
end

def get_pages_count
  url  = 'https://waysandmeans.house.gov/category/press-releases/'
  html = connect_to(url)
  doc  = Nokogiri::HTML(html)
  doc.xpath('//div[@class="pagination-wrapper center"]//li')[-2].text.strip.to_i
end
