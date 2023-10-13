# frozen_string_literal: true
class NpsParser < Hamster::Parser
  def get_cleaned_json(response)
    data = JSON.parse(response.gsub('jQuery1124037520536038033114_1641456095209(','')[0..-3])
    data["response"]["docs"]
  end

  def inner_page_parser(document,link,record,run_id)
    document = Nokogiri::HTML(document.force_encoding("utf-8"))
    lang_tag = document.css("html").first["lang"]
    dirty_news = 0
    dirty_news = 1 if !(lang_tag.nil?) and !(lang_tag.downcase.include? "en")
    return if document.css("div#main").empty?
    article_doc = fetch_article(document, %w[img iframe figure script .InfoAccordian .-auto-width .SharedContentTags .Component table])
    return if article_doc.nil?
    article = article_doc.to_html.strip
    dirty_news = 1 if article.length < 100
    date = record["Date_Released"].split("T").first.to_date rescue nil
    title = record["Title"].strip rescue nil
    dirty_news = 1 if article.length < 100
    teaser = fetch_teaser(article_doc,dirty_news)
    return if teaser.nil?
    teaser = cleaning_teaser(teaser)
    contact_info,city,state = fetch_contact_address(document,article_doc)
    tags = document.css("div.SharedContentTags a").map{|e| e.text.strip}
    with_table = document.css("table").empty? ? 0 : 1
    data_hash = {
      title: title,
      teaser: teaser,
      contact_info: contact_info,
      article: article.to_s,
      link: link,
      date: date,
      city: city,
      state: state,
      with_table: with_table,
      dirty_news: dirty_news,
      run_id: run_id,
    }
    [data_hash,tags]
  end

  def fetch_contact_address(document,article)
    unless document.css("div.ParkFooter-contact").first.nil?
      contact_info = document.css("div.ParkFooter-contact").first.to_s rescue nil
      city = document.css("span[itemprop='addressLocality']").first.text.strip rescue nil
      state = document.css("span[itemprop='addressRegion']").first.text.strip rescue nil
      return [contact_info,city,state]
    else
      contact_info = article.css("p").select{|e| e.text.include? "Contact:" rescue next}.first
      contact_info = contact_info.to_s unless contact_info.nil?
      return [contact_info,nil,nil]
    end
  end

  def fetch_article(document, list)
    article = (document.css("div#main .clearfix").empty?) ? document.css("div.col-sm-9") : document.css("div#main .clearfix") 
    return if article.nil?
    list.each {|tag| article.css(tag).remove}
    article
  end

  def fetch_teaser(article, dirty_news)
    teaser = nil
    return teaser if dirty_news == 1
    article.css("*").each do |node|
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
