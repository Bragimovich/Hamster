class Parser < Hamster::Parser
  DATA_SOURCE_URL = "https://www.fdic.gov/news/press-releases/index.html"

  def get_current_html_year(page)
    doc = Nokogiri:: HTML(page)
    doc.css('section article a').select{|s| s['href'].include? 'current.html'}[0].text
  end

  def get_json_inner_links(response)
    page = JSON.parse(response)
    links = page["pressReleases"].map{|a| a["href"]}    
  end

  def get_article(page, link, date, title, release)
    dirty_news = 0
    doc = Nokogiri::HTML(page)
    lang_tag = doc.css("html").first["lang"]
    dirty_news = 1 if !(lang_tag.nil?) and !(lang_tag.downcase.include? "en")
    article_doc = fetch_article(page)
    article = article_doc.to_html.strip
    teaser = fetch_teaser(article_doc, dirty_news)
    title = doc.css("div.prtitle h1").text.strip
    contact_info =  doc.css("div.contactinfo").to_html.strip unless doc.css("div.contactinfo").empty?
    contact_info =  doc.css("#media-contacts").to_html.strip unless doc.css("#media-contacts").empty?
    {
      title: title,
      teaser: teaser,
      article: article.to_s,
      link: link,
      date: date,
      contact_info: contact_info, 
      dirty_news: dirty_news,
      release_number: release,
      data_source_url: DATA_SOURCE_URL
    }
  end

  def get_data_json(page)
    page      = JSON.parse(page)
    links     = page["pressReleases"].map{|a| a["href"]}
    dates     = page["pressReleases"].map{|a| a["date"]}
    titles    = page["pressReleases"].map{|a| a["title"]}
    releases  = page["pressReleases"].map{|a| a["pr"]}
    [links, dates, titles, releases]
  end

  def remove_unnecessary_tags(doc, list)
    list.each { |tag| doc.css(tag).remove }
    doc
  end

  def fetch_article(file_content)
    article_doc = Nokogiri::HTML(file_content).css("div.grid-container article p")
    remove_unnecessary_tags(article_doc, %w[img iframe figure script])
  end

  def fetch_teaser(article, dirty_news)
    teaser = nil
    return teaser if dirty_news == 1
    article.css("p").each do |node|
      next if node.text.squish == ""
      next if node.text.squish[-5..-1].nil?
      if node.text.squish.length > 100
        teaser = node.text.squish
        break
      end
    end

    if teaser.nil?
      article.children.each do |node|
        next if node.text.squish == ""
        next if node.text.squish[-5..-1].nil?
        if node.text.squish.length > 100
          teaser = node.text.squish
          break
        end
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
    teaser_temp = teaser
    if teaser.length > 600
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? "."}
      dot = dot.uniq
      ind = teaser.index dot[-1]
      teaser = teaser[0..ind].join(" ")
    end
    if teaser.length  < 80
      teaser = teaser_temp[0..600].split
      dot = teaser.select{|e| e.include? ":"}
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
    elsif teaser[0..18].upcase.include? 'WASHINGTON' and  teaser[0..10].include? '('
      teaser = teaser.split(')' , 2).last.strip
    end
    teaser
  end

  def get_inner_links(page)   # For archived years
    page = Nokogiri::HTML(page)
    if page.css('div.contentlist li a').empty?
      page.css('#press_releases li a').map{|a| a['href']}
    else
      page.css('div.contentlist li a').map{|a| a['href']}
    end
  end

  def get_data_html(page)     # For archived years
    page = Nokogiri::HTML(page)
    if page.css('div.contentlist li a').empty?
      links   = page.css('#press_releases li a').map{|a| a['href']}
      dates   = page.css('#press_releases li span.date').map{|e| e.children.first.text}
      titles  = page.css('#press_releases li span.title a').map{|a| a.text.squish}
    else
      links   = page.css('div.contentlist li a').map{|a| a['href']}
      dates   = page.css('div.contentlist span.title').map{|e| e.children.first.text} if page.css('span.title')[0].children.count > 1
      dates   = page.css('div.contentlist span.date').map{|e| e.text}  if page.css('span.title')[0].children.count < 2
      titles  = page.css('div.contentlist span.title a').map{|a| a.text.squish}
    end
    [links, dates, titles]
  end

  def fetch_article_html(file_content)  # For archived years
    content = Nokogiri::HTML(file_content)
    article_doc = content.css("#content").empty? ? content.css("#print_content") : content.css("#content")
    remove_unnecessary_tags(article_doc, %w[strong table.media_contacts img iframe figure script])
  end

  def get_article_html(page, link, date, title)  # For Archived years
    dirty_news = 0
    doc = Nokogiri:: HTML(page)
    lang_tag = doc.css("html").first["lang"]
    dirty_news = lang_tag && (lang_tag.downcase.include? "en") ? 0 : 1
    article_doc = fetch_article_html(page)
    release_number =doc.css("#content").children[-2].css("strong").text.gsub("FDIC:","") rescue doc.css("#print_content strong")[-1].text.gsub("FDIC:","").squish rescue nil
    article_doc = fetch_article_html(page)
    article = article_doc.to_html.strip
    teaser = fetch_teaser( article_doc, dirty_news)
    title = title.gsub(/(<[^>]*>)|\n|\t/s){""}.gsub("Joint Release/", "").squish
    contact_info = doc.css("#content table.media_contacts").to_html.strip unless doc.css("#content table.media_contacts").empty?
    contact_info = doc.css("div.media_contact").to_html.strip unless doc.css("div.media_contact").empty?
    contact_info = doc.css('table div [align="right"] strong').to_html.strip
    {
      title: title,
      teaser: teaser,
      article: article.to_s,
      link: link,
      date: date,
      contact_info: contact_info,
      dirty_news: dirty_news,
      release_number: release_number,
      data_source_url: DATA_SOURCE_URL
    }
  end
end
