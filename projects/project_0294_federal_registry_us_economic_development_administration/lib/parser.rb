class Parser <  Hamster::Parser

  def inner_links(response)
    links = parsing(response)
    links.css('.view__content .teaser__title').css('h3').map{|s| s.css('a').map{|s| "https://www.eda.gov"+s['href']}}.flatten.reject{|e| e.include? 'https://www.commerce.gov/'}
  end

  def link_data(link,link_file,run_id)
    document = parsing(link_file)
    title = document.css('.l-page__content-layout h1').text
    contact_info, date = get_contact_info(document)
    dirty_news = (document.css('html').attribute('lang').text.include? "en") ? 0 : 1
    article = fetch_article(document)
    subtitle = fetch_subtitle(document)
    with_table = article.css("table").empty? ? 0 : 1
    teaser = fetch_teaser(article)
    article = article.nil? ? nil : article.to_s    
    data_hash = {
      title: title,
      subtitle: subtitle,
      teaser: teaser,
      article: article,
      date: date,
      link: link,
      contact_info: contact_info,
      dirty_news: dirty_news,
      with_table: with_table,
      data_source_url: "https://www.eda.gov/news?f%5B0%5D=type%3APress%20Release",
      run_id: run_id
    }
    data_hash = mark_empty_as_nil(data_hash)
    data_hash
  end

  def tags(response)
    body = parsing(response)
    all_tag_texts = body.css('.view__content .teaser__tags')[1].css('li').map(&:text)
    tag_array = []
    all_tag_texts.each do |tag|
      data_hash = {}
      data_hash[:tag] = tag.squish
      tag_array << data_hash
    end
    tag_array
  end

  private

  def parsing(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

  def get_contact_info(document)
    contact_info = document.css('.field__content')[1].text rescue nil
    date = document.css('.field__content')[0].text rescue nil
    [contact_info,date]
  end

  def remove_unnecessary_tags(doc, list)
    list.each { |tag| doc.css(tag).remove }
    doc
  end

  def fetch_article(document)
    article = document.css('.l-page__body-content')
    remove_unnecessary_tags(article, %w[img iframe figure script])
    article
  end

  def fetch_subtitle(document)
    document.css(".l-page__main .page-subtitle").text
  end

  def fetch_teaser(article)
    teaser = nil
    outer_teaser = ''
    article.children.each do |node|
      next if node.text.squish == ""
      if (node.text.squish == '.' or node.text.squish[-5..-1].include? "." or node.text.squish[-5..-1].include? ":") and node.text.squish.length > 50
        if outer_teaser != ''
          outer_teaser = outer_teaser + " " + node.text.squish  
        end
        teaser = node.text.squish
        break
      else
        outer_teaser = outer_teaser + " " + node.text.squish
      end
    end
    outer_teaser = outer_teaser.squish
    if teaser == '-' or teaser.nil? or teaser == ""
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = parsing(data[0]).text.squish
        next if teaser == ""
        if (teaser[-2..-1].include? "." or teaser[-2..-1].include? ":") and teaser.length > 100
          break
        elsif teaser.length > 100
          break  
        end
      end
    end
    teaser = outer_teaser != '' ? outer_teaser : teaser
    full_teaser = teaser
    if teaser.length > 600
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? "."}
      if dot == ['D.C.']
        teaser = teaser.join(" ")+":"
      else
        dot = dot.uniq
        all_indexes = teaser.each_index.select{|i| teaser[i] == dot[-1]}        
        teaser = teaser[0..all_indexes[-1]].join(" ")
        if teaser.size < 80
          teaser = full_teaser[0..600]+":"  
        end  
      end
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
    elsif teaser[0..50].include? ' - '
      teaser = teaser.split('-' , 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? "Washington" or teaser[0..50].include? "WASHINGTON"
        teaser = teaser.split('-' , 2).last.strip
      end
    end
    teaser
  end

end
