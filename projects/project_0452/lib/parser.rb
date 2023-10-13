# frozen_string_literal: true

TEASER_LEN = 600

class Parser < Hamster::Parser
  def get_json(source)
    page = Nokogiri::HTML source
    JSON.parse(page.css('p').children.text)
  end

  def get_alternative_json(source)
    page = Nokogiri::HTML source
    articles = page.css('article.article-card')
    pp res = (articles.map do |article|
      {
        url:      article.css('a')[0]['href'],
        title:    article.css('a')[0].text.strip,
        category: [article.css('div.usa-tag').text.strip],
        summary:  nil,
        programs: nil
      }.stringify_keys
    end)
    {items: res}.stringify_keys
  end

  def get_count_from_web(source) # total number of articles in JSON
    get_json(source)["count"].to_i
  end

  def proper_teaser(article_block)
    p_array = (article_block.css('p').size < 2) ? article_block.css('div') : article_block.css('p')
    str = p_array[0].text
    str += p_array[1].text if str.length < 5
    str += " #{p_array[2].text}" if (str.length < 50 && !!p_array[2]) # if teaser is too short
    str = (str.split.map {|el| el.strip}).join(' ')
    return str if str.length <= TEASER_LEN

    res = str[0..TEASER_LEN-1].split('.')[0..-2].join('.')
    return res if res != ""

    tmp = str[0..TEASER_LEN - 1]
    teaser = tmp[0..tmp.rindex(' ')-1] + '…'
  end

  def release_number(str)
    return nil if str.size < 4
    arr = str.split
    shift_flag = true
    while shift_flag do
      shift_flag = false
      next if arr.empty?
      shift_flag = true if arr[0] == 'de'
      shift_flag = true if arr[0].length > 2 && arr[0].to_i == 0 && arr[0][2..-1].to_i == 0
      arr.shift if shift_flag
    end
    arr.join(' ')
  end

  def blank_article(item)
    type = item["category"].uniq.join(' / ')
    article_data = {
      title:          item["title"],
      subtitle:       item["summary"],
      date:           Date.parse(item["url"]),
      link:           URL + item["url"],
      program:        item["programs"].uniq.join(' / '),
      type:           type.empty? ? 'press release' : type.downcase,
      dirty_news:     1
    }
  end

  def parse(item)
    link = URL + item["url"]
    type = item["category"].uniq.join(' / ')
    hammer = Hamster::Scraper::Dasher.new(using: :hammer)
    page = body = article_block = nil
    1.upto(3) do |i| # trying to download page 3 times
      page = hammer.get(link)
      body = Nokogiri::HTML (page)
      article_block = body.css('.usa-prose')
      [STARS, article_block.to_s.size, article_block.text.size].each {|line| logger.debug(line)}
      break if article_block.text.size != 0
    end
    return blank_article(item) if article_block.text.size == 0
    item["summary"] ||= body.css('div.sba-article__summary')&.text
    related_programs_text = body.css('div.sba-article__related-programs')&.text
    item["programs"] ||= related_programs_text.split(':').last.split(',').map(&:strip) rescue Array.new

    header = body.css('h1')
    rn_block = body.css('.sba-article__classification').text
    date_block = body.css('time').text
    date_block.gsub!(' de ', ' ')
    date = ( Date.parse(date_block) rescue Date.parse(item["url"]) )
    # begin
    #   date = Date.parse(rn_block.size > 3 ? date_block : item["url"])
    # rescue StandardError => e
    #   [STARS,  e].each {|line| logger.error(line)}
    # end
    article_data = {
      title:          item["title"],
      subtitle:       item["summary"],
      teaser:         proper_teaser( article_block ),
      article:        article_block.to_s,
      date:           date,
      link:           link,
      release_number: release_number(rn_block),
      program:        item["programs"].uniq.join(' / '),
      contact_info:   contact_info(body),
      type:           type.empty? ? 'press release' : type.downcase,
      dirty_news:     (type == "Comunicado de prensa") || (article_block.to_s.length < 200) || article_block.to_s.include?(' la ') ? 1 : 0,
      with_table:     article_block.css('table').empty? ? 0 : 1
    }
  end

  def contact_info(body)
    contact_card = body.css('.sba-person-small-card')
    contact_card.search('svg').each do |src|
      src.remove
    end
    contact_card.to_s
  end
end
