# frozen_string_literal: true

class OmctpParser < Hamster::Parser

  def initialize
    super
  end

  def get_outer_records(outer_page)
    parse_nokogiri(outer_page).css('#col_json_result li')
  end

  def get_check_value(page)
    parse_nokogiri(page).css('.article-meta').text
  end

  def get_inner_links(main_page)
    parse_nokogiri(main_page).css('#col_json_result li a').map{|a| a['href'] if a['target'] != "_blank"}.compact
  end

  def get_total_length(main_page)
    data = parse_nokogiri(main_page) 
    data.css("#pagination select option").first.text.to_i * data.css(".page-numbers")[-2].text.to_i
  end

  def process_outer_record(record)
    title = record.css("a").first.text.strip
    date = record.css("div.collection-result-meta span[dir='ltr']").first.text rescue nil
    date = (date.nil?) ? nil : Date.parse(date)
    link = record.css("a").first["href"]
    [title, date, link]
  end

  def parse(file_content, title, date, link)
    doc = parse_nokogiri(file_content)
    lang_tag = doc.css("html").first["lang"]
    dirty_news = 0
    dirty_news = 1 if !(lang_tag.nil?) and !(lang_tag.downcase.include? "en")
    article_doc = fetch_article(doc)
    return if article_doc.nil?
    article_doc.css('div').find_all {|div| all_children_are_blank?(div)}.each do |div|
      div.remove
    end
    article = article_doc.children.to_html.strip
    dirty_news = 1 if article.length < 100
    teaser = fetch_teaser(article_doc, dirty_news)
    type = doc.css(".article-meta.doctype-meta").first.text.strip rescue 'press release'
    bureau_office = doc.css(".article-meta__author-bureau a , .report-meta__author a").first.text.strip rescue nil
    with_table = article_doc.css("table").empty? ? 0 : 1
    country = doc.css(".related-tags__pills a").select{|e| e['href'].include? "countries"}.first.text.strip rescue 'US'
    tags = doc.css(".related-tags__pills a").map{|e| e.text.strip}
    data_hash = {
      title: title,
      teaser: teaser,
      article: article,
      bureau_office: bureau_office,
      country: country,
      type: type,
      link: link,
      date: date,
      with_table: with_table,
      dirty_news: dirty_news,
    }
    [data_hash, tags]
  end

  private

  def is_blank?(node)
    (node.text? && node.content.strip == '') || (node.element? && node.name == 'br')
  end

  def all_children_are_blank?(node)
    node.children.all? {|child| is_blank?(child)}
  end

  def fetch_article(data)
    article_doc = data.css("#content .entry-content , div.report__content , div.field.field-name-body.field-type-text-with-summary, div.summary ul.summary__list").first rescue nil
    unless article_doc.nil?
      article_doc = remove_unnecessary_tags(article_doc, %w[img iframe figure script]) 
    end
    article_doc
  end

  def remove_unnecessary_tags(doc, list)
    list.each { |tag| doc.css(tag).remove }
    doc
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
        teaser = parse_nokogiri(data.first).text.squish 
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
  cleaning_teaser(teaser)
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
  private
  def parse_nokogiri(page)
    Nokogiri::HTML(page)
  end
end
