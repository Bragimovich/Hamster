# frozen_string_literal: true
class Parser < Hamster::Parser
  
  DOMAIN = 'https://www.aphis.usda.gov'

  def get_inner_links(outer_page)
    outer_page = Nokogiri::HTML(outer_page)
    outer_page.css('#DataTable tr td a').map{|a| DOMAIN+a['href']}
  end

  def get_outer_records(outer_page)
    outer_page = Nokogiri::HTML(outer_page)
    outer_page.css('#DataTable tr')
  end

  def process_outer_record(record)
    title = record.css("td")[1].text.strip
    link = DOMAIN + record.css("a")[0]['href']
    date = record.css("td")[0].text
    date = DateTime.strptime(date, "%m/%d/%y").to_date rescue "-"
    type = record.css("td")[2].text.strip rescue 'press release'
    cateogry = record.css("td")[3].text.strip
    [title, link, date, type, cateogry]
  end

  def parse(file_content, title, link, date, type,cateogry)
    @doc = Nokogiri::HTML(file_content)
    p link.yellow
    release_check = @doc.css("div.span8 > p").first.text.strip rescue nil
    return if release_check.nil?
    lang_tag = @doc.css("html").first["lang"]
    dirty_news = 0
    dirty_news = 1 if !(lang_tag.nil?) and !(lang_tag.downcase.include? "en")
    article_doc = fetch_article(file_content)
    article = article_doc.children.to_html.squish
    dirty_news = 1 if article.length < 100
    teaser = fetch_teaser(article_doc, dirty_news)
    first_para  = @doc.css("div.span8 > p")[0].text
    second_para = @doc.css("div.span8 > p")[1..3].text
    last_para   = @doc.css("div.span8 > p")[-1].text
    if(first_para.include?("Contact"))
      contact = @doc.css("div.span8 > p")[0]
    elsif(second_para.include?("Contact"))
      contact = @doc.css("div.span8 > p")[1].text.split("WASHINGTON").first
    elsif(last_para.include?("contact"))
      contact = @doc.css("div.span8 > p")[-1]
    end
    if date.nil?
      date = @doc.css(".article-meta__publish-date, .report-meta__date, .field.field-name-field-date").first.text.strip rescue nil
      date = Date.parse(date).to_date rescue nil
    end
    with_table = article_doc.css("table").empty? ? 0 : 1
    cateogry=cateogry.split(",")
    data_hash = {
      title: title.to_s,
      teaser: teaser.to_s,
      article: article.to_s,
      type: type.to_s,
      link: link,
      date: date,
      contact_info: contact.to_s,
      with_table: with_table,
      dirty_news: dirty_news,
    }
    data_hash = mark_empty_as_nil(data_hash)
    [data_hash, cateogry]
  end

  private

  def is_blank?(node)
    (node.text? && node.content.strip == '') || (node.element? && node.name == 'br')
  end

  def all_children_are_blank?(node)
    node.children.all? {|child| is_blank?(child)}
  end

  def fetch_article(file_content)
    article_doc = Nokogiri::HTML(file_content).css("div.span8")
    article_doc.css("img").remove
    article_doc.css("iframe").remove
    article_doc.css("figure").remove
    article_doc.css("script").remove
    article_doc.css("comment()").remove
    article_doc.css("h1").remove
    article_doc.css("div").remove
    article_doc.css("p[style = 'text-align: right;']").remove
    article_doc.css("p[align = 'right']").remove
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
    cleaning_teaser(teaser).split(".gov").last
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

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == 'N/A') ? nil : value.to_s.squish}
  end

end
