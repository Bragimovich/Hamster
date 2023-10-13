# frozen_string_literal: true
class Parser < Hamster::Parser

  def get_links(html)
    url   = 'https://www.usmarshals.gov'
    body  = Nokogiri::HTML(html.force_encoding('utf-8'))
    body.css(".usa-collection__footer li a").map { |link| url+link['href'] }
  end

  def parser(html, link, run_id)
    data_hash  = {}
    dirty_news = 0
    body                        = Nokogiri::HTML(html)
    lang_tag                    = body.css('html').first['lang']
    dirty_news                  = 1 unless (lang_tag.nil?) or (lang_tag.downcase.include? 'en')
    data_hash[:title]           = body.css('div.block-field-blocknodenewstitle h1').text
    data_hash[:link]            = link
    data_hash[:date]            = body.css('time').text
    article                     = fetch_article(html)
    data_hash[:article]         = article.to_html
    teaser                      = fetch_teaser(article, dirty_news)
    data_hash[:teaser]          = teaser
    data_hash[:dirty_news]      = dirty_news
    data_hash[:contact_info]    = body.css('section.block--releaseinfo div.grid-container div.layout__region--second').to_html
    data_hash[:data_source_url] = 'https://www.usmarshals.gov/news-release/2171'
    data_hash[:run_id]          = run_id
    data_hash
  end

  def remove_unnecessary_tags(doc, list)
    list.each { |tag| doc.css(tag).remove }
    doc
  end

  def fetch_article(html)
    article_doc = Nokogiri::HTML(html).css('div.block-field-blocknodenewsbody')
    remove_unnecessary_tags(article_doc, %w[img iframe figure script])
  end

  def fetch_teaser(article, dirty_news)
    teaser = nil
    return nil if dirty_news == 1

    article.css('p').each do |node|
      next if node.text.squish.empty? or node.text.squish[-5..].nil?

      if node.text.squish.length > 100
        teaser = node.text.squish
        break

      end
    end

    if teaser.nil?
      article.children.each do |node|
        next if node.text.squish.empty? or node.text.squish[-5..].nil?

        if node.text.squish.length > 100
          teaser = node.text.squish
          break

        end
      end
    end

    if teaser == '-' or teaser.nil? or teaser.empty?
      data_array = article.css('*').to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.push(article.to_s) if data_array.empty?
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish 
        next if teaser.empty? or teaser[-2..].nil? or teaser.length > 100

      end
    end
    teaser_temp = teaser
    if teaser.length > 600
      teaser = teaser[0..600].split
      dot = teaser.select{|e| e.include? '.'}.uniq
      ind = teaser.index dot[-1]
      teaser = teaser[0..ind].join(' ')
    end
    if teaser.length  < 80
      teaser = teaser_temp[0..600].split
      dot = teaser.select { |e| e.include? ':' }.uniq
      ind = teaser.index dot[-1]
      teaser = teaser[0..ind].join(' ')
    end
    return nil if teaser.length  < 20

    teaser[-1].include? ':' ? teaser[-1] = '...' : teaser
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
      if teaser[0..50].include? 'Washington' or teaser[0..50].include? 'WASHINGTON'
      teaser = teaser.split('-' , 2).last.strip
      end
    elsif teaser[0..18].upcase.include? 'WASHINGTON' and  teaser[0..10].include? '('
      teaser = teaser.split(')' , 2).last.strip
    end
    teaser
  end

end
