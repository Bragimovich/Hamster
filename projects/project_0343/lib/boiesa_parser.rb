# frozen_string_literal: true

class BoiesaParser < Hamster::Parser

  DOMAIN = 'https://www.state.gov'
  SUB_PATH = '/remarks-and-releases-bureau-of-oceans-and-international-environmental-and-scientific-affairs/?results=99999&gotopage=&total_pages=7&coll_filter_year=&coll_filter_month=&coll_filter_speaker=&coll_filter_country=&coll_filter_release_type=&coll_filter_bureau=&coll_filter_program=&coll_filter_profession='
  SUB_FOLDER = 'oceans_and_scientific_affairs'
 
  def initialize
    super
  end

  def get_inner_links(main_page)
    @document = Nokogiri::HTML(main_page)
    links = @document.css('#col_json_result li a').map{|a| a['href']}
  end

  def parse(file_content, link)
    p link.yellow
    @doc = Nokogiri::HTML(file_content)
    title = @doc.css("h1.featured-content__headline.stars-above, h1.title").first.text.strip rescue "not_found"
    return [{},[]] if title == "not_found"
    lang_tag = @doc.css("html").first["lang"]
    dirty_news = 0
    dirty_news = 1 if !(lang_tag.nil?) and !(lang_tag.downcase.include? "en")

    article_doc = fetch_article(file_content)
    article_doc.css('div').find_all {|div| all_children_are_blank?(div)}.each do |div|
      div.remove
    end
    article = article_doc.children.to_html.strip
    dirty_news = 1 if article.length < 100
    teaser = fetch_teaser(article_doc, dirty_news)
   
    type = @doc.css(".article-meta.doctype-meta").first.text.strip rescue 'press release'
    bureau_office = @doc.css(".article-meta__author-bureau a, .report-meta__author a").first.text.strip rescue nil
    date = @doc.css(".article-meta__publish-date, .report-meta__date, .field.field-name-field-date").first.text.strip rescue nil
    date = Date.parse(date).to_date rescue nil

    with_table = article_doc.css("table").empty? ? 0 : 1
    country = @doc.css(".related-tags__pills a").select{|e| e['href'].include? "countries"}.first.text.strip rescue 'US'
    tags = @doc.css(".related-tags__pills a").map{|e| e.text.strip}
    
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
    return [data_hash, tags]
  end

  private 
  
  def is_blank?(node)
    (node.text? && node.content.strip == '') || (node.element? && node.name == 'br')
  end

  def all_children_are_blank?(node)
    node.children.all? {|child| is_blank?(child)}
  end

  def fetch_article(file_content)
    article_doc = Nokogiri::HTML(file_content).css("#content .entry-content, div.report__content, div.field.field-name-body.field-type-text-with-summary, div.summary ul.summary__list").first
    
    article_doc.css("img").remove
    article_doc.css("iframe").remove
    article_doc.css("figure").remove
    article_doc.css("script").remove
    article_doc
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
      teaser = teaser.split('–', 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—', 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--', 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('‒', 2).last.strip
    elsif teaser[0..50].include? ' - '
      teaser = teaser.split('-', 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
      teaser = teaser.split('-', 2).last.strip
      end
    elsif teaser[0..18].upcase.include? 'WASHINGTON' and  teaser[0..10].include? '('
      teaser = teaser.split(')', 2).last.strip
    end
    teaser
  end
end
