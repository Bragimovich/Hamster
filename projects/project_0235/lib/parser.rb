# frozen_string_literal: true
class Parser < Hamster::Parser

  DOMAIN = "https://www.justice.gov"

  def get_inner_links(response,flag)
    page = parse_page(response,flag)
    [page.css("div.rows-wrapper a").map{|e| DOMAIN + e["href"]},page]
  end

  def parse_data(inner_page_content,link,run_id)
    document = parse_page(inner_page_content,'parse')
    data_array = []
    title = document.css(".node-title", "#node-title").first.text.strip rescue nil
    date, bureau_office, contact_info, release_no, tags, state, subtitle = fetch_data(document) unless title.nil?
    title, date, bureau_office, contact_info, release_no, tags, state, subtitle = fetch_data_for_changed_formate(document) if title.nil?
    contact_info = contact_info == "" ? nil : contact_info
    bureau_office = "#{bureau_office[0..250]}#{bureau_office[-1] = '...'}" if bureau_office.size > 250 rescue nil
    release_no = nil if release_no.size > 50 rescue nil
    article = fetch_article(document)
    with_table = article.css("table").empty? ? 0 : 1
    teaser = fetch_teaser(article)
    (teaser.nil? || teaser.empty?) ? dirty_news = 1 : dirty_news = 0
    data_hash = {
      title: title,
      teaser: teaser,
      subtitle: subtitle,
      contact_info: contact_info,
      release_no: release_no,
      article: article.to_s,
      link: link,
      data_source_url: "https://www.justice.gov/usao/pressreleases",
      date: date,
      bureau_office: bureau_office,
      state: state,
      with_table: with_table,
      dirty_news: dirty_news,
      run_id: run_id
    }
    data_hash = mark_empty_as_nil(data_hash)
    [data_hash,tags]
  end

  private

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value}
  end

  def parse_page(response,flag)
   flag == 'body' ? Nokogiri::HTML(response.body.force_encoding("utf-8")) : Nokogiri::HTML(response.force_encoding("utf-8"))
  end   

  def fetch_data(document)
    bureau_office,contact_info,release_no,state = get_common_values(document)
    subtitle      = document.css(".node-subtitle", "#node-subtitle").first.text.strip rescue nil
    date          = document.css(".date-display-single").first["content"].split("T").first rescue nil
    tags          = document.css(".field.field--name-field-pr-topic .field__items div").map{|e| e.text.strip}
    [date, bureau_office, contact_info, release_no, tags, state, subtitle]
  end

  def fetch_data_for_changed_formate(document)
    bureau_office,contact_info,release_no,state = get_common_values(document)
    title         = document.css("h1.page-title").first.text.strip rescue nil
    date          = document.css("time")[0].text.to_date rescue nil?
    tags          = document.css("div.field__items").first.css("div").map{|e| e.text.strip} rescue nil
    [title, date, bureau_office, contact_info, release_no, tags, state, nil]
  end

  def get_common_values(document)
    bureau_office = document.css(".field.field--name-field-pr-component a").text.strip rescue nil
    bureau_office = document.css(".field-formatter--entity-reference-label a").text.strip if bureau_office.empty? rescue nil
    contact_info  = document.css(".field.field--name-field-pr-contact").first.to_s
    release_no    = document.css(".field.field--name-field-pr-number .field__items").first.text.strip rescue nil
    release_no    = document.at_css('.node-content.node-press-release').text.split(':').last.squish if release_no.nil? rescue nil
    state         = fetch_state(bureau_office)
    [bureau_office,contact_info,release_no,state]
  end

  def fetch_state(value)
    (value.include? "-") ? value.split("-").last.strip : nil
  end

  def fetch_article(document)
    article = document.css("div.field--name-field-pr-body div.field__items") rescue nil
    article = document.css('div.node-body') if article.nil? || article.empty?
    remove_unnecessary_tags(article, %w[img iframe figure script])
    article
  end

  def remove_unnecessary_tags(doc, list)
    list.each { |tag| doc.css(tag).remove }
    doc
  end

  def fetch_teaser(article)
    teaser = nil
    article.css("*").each do |node|
      next if node.text.squish == ""
      if (node.text.squish[-10..].include? ".") || (node.text.squish[-10..].include? ":") && (node.text.squish.length > 50)
        teaser = node.text.squish
        break
      end
    end
    if (teaser == '-') || (teaser.nil?) || (teaser == "")
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser == ""

        if (teaser[-2..].include? ".") || (teaser[-2..].include? ":") && (teaser.length > 100)
          break
        end
      end
    end
    return nil if teaser.nil?
    teaser = dot_handling(teaser)
    if teaser.length  < 20
      return nil
    end
    if teaser[-1].include? ":"
      teaser[-1] = "..."
    end
    cleaning_teaser(teaser)
  end

  def dot_handling(teaser)
    if teaser.length > 600
      outer_teaser = teaser
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? "."}
      if (dot.count <= 3) && (teaser[0..(teaser.index dot[-1])].join(" ").size < 100)
        teaser = teaser.join(" ")
      elsif (dot.count == 1) && (dot.first.size == 2)
        teaser = teaser.join(" ")[0..590]+":"
      else
        all_indexes = []
        teaser.each_with_index{|e, index| all_indexes << index if e.include? '.'}
        counter = all_indexes.size
        while true
          break if counter == 0
          if teaser[0..all_indexes[-1]].join(" ").size > 600
            counter -=1
            all_indexes.pop
          else
            teaser = teaser[0..all_indexes[-1]].join(" ")
            break
          end
        end
        if (teaser[-3..-1].include? ' ') && (teaser[-3..-1].include? '.') && (teaser[-3..-1].scan(/\w/).count == 1)
          teaser = outer_teaser[0..590].split.join(" ")+":"
        end
      end
    end
    teaser
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
      if (teaser[0..50].include? "Washington") || (teaser[0..50].include? "WASHINGTON")
        teaser = teaser.split('-' , 2).last.strip
      end
    end
    teaser
  end
end
