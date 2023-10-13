


def parse_list_news(html)
  doc = Nokogiri::HTML(html)
  arcticle_array = []
  table = doc.css('.idx')[0]
  table.css('tr').each do |news|
    title_link = news.css('.h')[0]
    title = title_link.content

    link = title_link.css('a')[0]['href']
    prlog_id = link.split('-')[0][1..].to_i
    creator = news.css('.m')[0].content.split('By ')[-1]
    teaser = news.css('.s')[0].content
    arcticle_array.push({:title => title,:link=>link, :teaser=>teaser, :creator=>creator, :prlog_id =>prlog_id })#:teaser=>teaser
  end
  next_page = doc.css('.nxt')
  return arcticle_array, next_page
end


def parse_one_news(html)
  news_hash = {:contact_info=>'', :tags=>[], :industries=>[]}
  doc = Nokogiri::HTML(html)
  tinfo = doc.css(".tinfo").css("tr")
  tinfo.each do |info|
    case info.css('th')[0].content
    when 'Location'
      location = info.css('.TL0')[0].css('a')
      news_hash[:country] = location[-1].content
      return if news_hash[:country]!='United States'
      if location.length>2
        news_hash[:city] = location[0].content
        news_hash[:state] = location[1].content
      elsif location.length>1
        news_hash[:city] = location[0].content
        news_hash[:state] = ''
      else
        news_hash[:city] = ''
        news_hash[:state] = ''
      end
    when 'Tags'
      info.css('.TL0')[0].css('a').map {|tag| news_hash[:tags].push(tag.content.downcase)}
    when 'Industry'
      info.css('.TL0')[0].css('a').map {|industry| news_hash[:industries].push(industry.content.downcase)}
    else
      news_hash[:contact_info]+=info.to_s
    end
  end

  return if news_hash[:country].nil?

  article_nokogiri = doc.css('[@id="abd"]')[0]
  #article_nokogiri.search('br').each { |br| br.replace('\n') }
  begin
    news_hash[:article] = article_nokogiri.to_s.split("PRLog</a></i>")[1].strip
  rescue
    return
  end
  news_hash[:files] = []

  if doc.at_css(".photolink")
    doc.css(".photolink a").each do |file|
      news_hash[:files].push(file['href'])
    end
  end

  news_hash
end