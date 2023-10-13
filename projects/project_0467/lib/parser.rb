# frozen_string_literal: true
class Parser < Hamster::Scraper

  def get_parsed_object(html)
    Nokogiri::HTML(html.force_encoding("utf-8"))
  end

  def get_links(html)
    body = get_parsed_object(html)
    body.css("#mdgovMain h3 a").map{|link| link['href']}
  end

  def get_dates(html)
    body = get_parsed_object(html)
    body.css("#mdgovMain time").map{|t| t.text}
  end

  def parser(html,link,run_id,date)
    data_hash = {}
    dirty_news = 0
    body = get_parsed_object(html)
    lang_tag = doc.css("html").first["lang"] rescue nil
    dirty_news = 1 if !(lang_tag.nil?) and !(lang_tag.downcase.include? "en")
    data_hash[:run_id] = run_id
    data_hash[:title] = body.css("#mdgovMain h1").text
    data_hash[:date] = date
    data_hash[:link] = link
    article = fetch_article_html(body)
    data_hash[:with_table] = article.css("table").empty? ? 0 : 1
    data_hash[:article] = article.to_html
    teaser = fetch_teaser(article,dirty_news)
    dirty_news = 1 if teaser.nil?
    data_hash[:teaser] = teaser
    data_hash[:dirty_news] = dirty_news
    data_hash
  end

  private

  def remove_unnecessary_tags(doc, list)
    list.each { |tag| doc.css(tag).remove }
    doc
  end

  def fetch_article_html(html)
    article_doc = html.css("#mdgovMain p")
    remove_unnecessary_tags(article_doc, %w[img iframe figure script comment() h1 h2 time p.wp-caption-text p[style][0] em])
    article_doc
  end

  def fetch_teaser(article, dirty_news)
    teaser = nil
    return teaser if dirty_news == 1
    article_temp = article
    article_temp = remove_unnecessary_tags(article_temp,%w[i br b strong h3 ul])

    article_temp.css("*").each do |node|
      next if node.text.squish == ""
      next if node.text.squish[-5..-1].nil?
      if node.text.squish.length > 100
        teaser = node.text.squish
        break
      end
    end

    if teaser.nil?
      article_temp.children.each do |node|
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
