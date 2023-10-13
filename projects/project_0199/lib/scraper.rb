# frozen_string_literal: true

require_relative '../models/faa'

class Scraper <  Hamster::Scraper
  URL = 'https://www.faa.gov/newsroom/press_releases?field_effective_date_value=&field_effective_date_value_1=&keys=&field_region_target_id=All&page='

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @already_processed = Faa.pluck(:link)
  end

  def scraper
    page_no = 0
    loop do
      url  = URL + page_no.to_s
      body = connect_to(url)
      break if page_no == 3

      parser(body, url)
      page_no += 1
    end
  end

  def parser(body, url)
    array = []
    data  = body.css('section.section div.view-faa-press-releases').css('.list_view_items .views-row')
    all_links = data.map { |e| "https://www.faa.gov#{e.css('.views-field-title a').first.attr('href')}" rescue nil }
    dates     = data.map { |e| e.css('.views-field-field-effective-date div').first.text rescue nil }
    all_links.each_with_index do |link, ind|
      next if @already_processed.include? link

      document     = connect_to(link)
      contact_info = document.css('p').select { |e| e.text.squish.include? 'Contact:' }.first rescue nil
      dirty_news   = ((document.css'*').attr('lang').value.include? 'en') ? 0 : 1
      title        = document.css('h1.page__title').text.squish
      article      = fetch_article(document)
      teaser       = fetch_teaser(article.css('div.mb-4.clearfix'))
      date         = Date.parse(dates[ind]).to_date rescue nil
      data_hash = {
        title: title,
        teaser: teaser,
        article: article.to_s,
        date: date,
        contact_info: contact_info,
        link: link,
        dirty_news: dirty_news,
        data_source_url: url
      }
      array.push(data_hash)
    end
    Faa.insert_all(array) unless array.empty?
  end

  def fetch_article(document)
    document.css('img').remove
    document.css('iframe').remove
    document.css('figure').remove
    document.css('script').remove
    document.css('article div.node__content').first
  end

  def fetch_teaser(article)
    teaser = nil
    article.children.each do |node|
      next if node.text.squish.empty?

      if (node.text.squish[-5..].include? '.' or node.text.squish[-5..].include? ':') and node.text.squish.length > 50
        teaser = node.text.squish
        break

      end
    end

    if teaser == '-' || teaser.nil? || teaser.empty?
      data_array = article.to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>|<p>)/)
      data_array.each do |data|
        teaser = Nokogiri::HTML(data[0]).text.squish
        next if teaser.empty?

        break if (teaser[-2..].include? '.' or teaser[-2..].include? ':') and teaser.length > 100

      end
    end

    return nil if teaser.nil?

    if teaser.length > 600
      teaser = teaser[0..600].split
      dot    = teaser.select { |e| e.include? '.' }.uniq
      ind    = teaser.index dot[-1]
      teaser = teaser[0..ind].join(' ')
    end
    (teaser[-1].include? ':') ? teaser[-1] = '...' : teaser
    cleaning_teaser(teaser)
  end

  def cleaning_teaser(teaser)
    if teaser[0..50].include? '–'
      teaser = teaser.split('–', 2).last.strip
    elsif teaser[0..50].include? '—'
      teaser = teaser.split('—', 2).last.strip
    elsif teaser[0..50].include? '--'
      teaser = teaser.split('--', 2).last.strip
    elsif teaser[0..50].include? ' - '
      teaser = teaser.split('-', 2).last.strip
    elsif teaser[0..50].include? '-'
      if teaser[0..50].include? 'Washington' or teaser[0..50].include? 'WASHINGTON'
        teaser = teaser.split('-', 2).last.strip
      end
    end
    teaser
  end

  def connect_to(url)
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or response&.status == 404 or retries == 10
    Nokogiri::HTML(response.body.force_encoding('utf-8'))
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = response.status.to_s
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
  end
end
