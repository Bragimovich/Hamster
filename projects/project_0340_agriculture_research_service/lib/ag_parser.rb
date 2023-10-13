# frozen_string_literal: true

class AGParser < Hamster::Parser

  DOMAIN = 'https://www.ars.usda.gov'
  SUB_PATH = '/news-events/news-archive/?year='
 
  def initialize
    super
  end

  def get_inner_links(main_page)
    document = Nokogiri::HTML(main_page)
    a_tags = document.css('.usa-layout-docs-main_content tbody td > a')
    return [] if a_tags.empty?
    links = a_tags.map{|a| DOMAIN + a['href']}
  end

  def parse(file_content, main_page, link, year)
    p link
    main_page = Nokogiri::HTML(main_page)
    main_page_data = main_page.css(".usa-width-three-fourths tbody tr")[1..-1].select{|e| link.include? e.css("a")[0]['href'] rescue next}[0]
    date = main_page_data.css("td")[0].text.strip + ", " + year
    date = Date.parse(date).to_date rescue nil
    title = main_page_data.css("a")[0].text.strip
   
    doc = Nokogiri::HTML(file_content)
    lang_tag = doc.css("html").first["lang"]
    dirty_news = 0
    dirty_news = 1 if !(lang_tag.nil?) and !(lang_tag.include? "en")

    article_doc = fetch_article(file_content)
    article_doc.css('div').find_all {|div| all_children_are_blank?(div)}.each do |div|
      div.remove
    end
    article = article_doc.children.to_html.strip
    teaser = fetch_teaser(article_doc)

    contact_info = doc.css("span[style*='margin'][style*='right'][style*='padding']")[0]
    contact_info = contact_info.nil? ? nil : contact_info.to_s
    with_table = article_doc.css("table").empty? ? 0 : 1
    data_hash = {
      title: title,
      teaser: teaser,
      article: article,
      contact_info: contact_info,
      link: link,
      date: date,
      data_source_url: DOMAIN + SUB_PATH + year,
      with_table: with_table,
      dirty_news: dirty_news,
    }
    data_hash
  end

  private

  def is_blank?(node)
    (node.text? && node.content.strip == '') || (node.element? && node.name == 'br')
  end

  def all_children_are_blank?(node)
    node.children.all? {|child| is_blank?(child)}
  end

  def fetch_article(file_content)
    article_doc = Nokogiri::HTML(file_content).css(".usa-width-three-fourths.usa-layout-docs-main_content").first
    article_doc.css('.usa-color-yellow-light.archive-font').remove
    article_doc.css("img").remove
    article_doc.css("iframe").remove
    article_doc.css("figure").remove
    article_doc.css("script").remove
    article_doc
  end

  def fetch_teaser(article)
    teaser = nil
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
