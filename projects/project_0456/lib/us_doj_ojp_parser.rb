class UsDojOjpParser < Hamster::Parser

  def get_article_html(page, link, date, title)
    dirty_news = 0
    doc = Nokogiri::HTML(page)
    lang_tag = doc.css("html").first["lang"] rescue nil
    dirty_news = 1 if !(lang_tag.nil?) and !(lang_tag.downcase.include? "en")
    article = fetch_article_html(page)
    teaser = fetch_teaser(article, dirty_news)
    subtitle = doc.css('p.text-align-center').reject{|p| p.text == '###'}[0].text rescue nil
    contact_info = get_contact_info(doc.css("div.use-float-friendly-lists p"))
    release_number = doc.css("div.use-float-friendly-lists p").select{|s| s.text.include? 'Press Release Number:'}[0].text.gsub('Press Release Number:', '').strip rescue nil
    data_hash = {
      title: title,
      teaser: teaser,
      article: article.to_s,
      link: link,
      subtitle: subtitle,
      date: Date.strptime(date, "%m/%d/%Y"),
      contact_info: contact_info,
      release_number: release_number,
      dirty_news: dirty_news,
      data_source_url: "https://www.ojp.gov/news/news-releases"
    }
    return data_hash
  end
  
  def get_inner_links(page)
    page = Nokogiri::HTML(page)
    page.css("div.use-float-friendly-lists p")[1..-3].css("p a").map{|a| a["href"]}.reject{|s| s.end_with? '.pdf'}  
  end

  def get_data_html(page)
    page = Nokogiri::HTML(page)
    date = page.css("div.use-float-friendly-lists p strong")[0..-2].map{|a| a.text.squish}
    title = page.css("div.use-float-friendly-lists p")[1..-3].css("p a").map{|a| a.text}
    links = page.css("div.use-float-friendly-lists p")[1..-3].css("p a").map{|a| a["href"]}  
    [links,date,title]
  end

  private

  def get_article_last_index(paragraphs)
    paragraphs.find_index{|p| p.text == '###'}
  end

  def get_contact_info(paragraphs)
    paragraphs.css('p').select{ |p| p.text.include? 'CONTACT:' }[0].to_html  rescue nil
  end

  def remove_unnecessary_tags(doc, list)
    list.each { |tag| doc.css(tag).remove }
    doc
  end

  def fetch_article_html(file_content)
    article_doc = Nokogiri::HTML(file_content).css("div.use-float-friendly-lists p")
    end_index = get_article_last_index(article_doc)
    article_doc = article_doc[0..end_index]
    remove_unnecessary_tags(article_doc, %w[img iframe figure script])
    article_doc
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
end
