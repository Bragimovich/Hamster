require_relative '../lib/keeper'
require_relative '../lib/project_parser'
require_relative '../lib/scraper'
require_relative '../models//ptd_embassy'

class Manager < Hamster::Harvester

  URL = 'https://washingtondc.embaixadaportugal.mne.gov.pt/en/the-embassy/news'
  COOKIE = 'user_consent={"level": ["necessary","analyticsv1","embededv1"]}; cookiesession1=678B2869483374F3871800D418C8A5DB; 2489d6682eb4e7a6ed8c3bc3eaee93dd=yQ/aoiFowjTExmKLgNwcKaPOFX/LNs7Hfrr9MQZJZuH7++nKSfT6lX7ht5QT7YPloqwDITkd6GKDQ1B0QjKYCw=='
  HEADERS = { authority: 'washingtondc.embaixadaportugal.mne.gov.pt',
              accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
              cookie: COOKIE }.freeze

  def initialize(**params)
    super
    @keeper = Keeper.new(PtdEmbassy)
    @scraper = Scraper.new
    @parser = ProjectParser.new
  end

  def download
    @parser.html = @scraper.body(use: 'connect_to', url: URL, ssl_verify: false,
                                 method: :get,  headers: HEADERS)
    if @parser.last_link.nil? || @parser.next_link.nil?
      @parser.pages_links.each { |url| save_data(url) }
    else
      last_link = @parser.last_link
      save_data(URL)
      until @parser.next_link.nil?
        url = @parser.next_link
        puts "url = #{url}".yellow
        save_data(url)
      end
      save_data(last_link)
    end
  end

  def save_data(url)
    html = @scraper.body(use: 'connect_to', url: url, ssl_verify: false,
                         method: :get,  headers: HEADERS)
    @parser.html = html
    titles = @parser.titles_data

    return if titles.blank?

    titles.each do |data|
      md5 = to_md5(data)
      filename = "news_page_#{md5}.html"
      save_html(@parser.html, filename, md5)
    end
    articles = []
    @parser.article_links.each do |url|
      @parser.html = @scraper.body(use: 'connect_to', url: url)
      article_data = @parser.article_data
      md5 = to_md5(article_data)
      filename = "news_article_#{md5}.html"
      save_html(@parser.html, filename, md5)
      articles << article_data
    end

    return if articles.blank?

    titles.each_with_index do |_, i|
      data = titles[i].merge(articles[i])
      @keeper.store(data)
    end
    @parser.html = html
  end

  def save_html(html, filename, md5_sum)
    peon.put(content: html.to_html.to_s, file: filename) unless peon.give_list.include?(md5_sum) || html.blank?
  end

  def to_md5(var)
    md5 = ''
    md5 = Digest::MD5.hexdigest var if var.is_a?(String)
    md5 = Digest::MD5.hexdigest var.join if var.is_a?(Array)
    md5 = Digest::MD5.hexdigest var.values.join if var.is_a?(Hash)
    md5
  end
end
