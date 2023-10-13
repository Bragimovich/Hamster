require_relative '../lib/keeper'
require_relative '../lib/project_parser'
require_relative '../lib/scraper'
require_relative '../models/fhfa'

class Manager < Hamster::Harvester
  URL = 'https://www.fhfa.gov'
  PATH = '/Media/Pages/News-Releases.aspx?k=ContentType%3APublic%2DAffairs%20AND%20PublicAffairsCategoryOWSCHCS%3A%22News%20Release%22%20AND%20FHFAPublishedDateOWSDATE%3D01%2F01%2F2022%2E%2E12%2F31%2F2022'

  def initialize
    super
    @keeper = Keeper.new(Fhfa)
    @scraper = Scraper.new
    @parser = ProjectParser.new
  end

  def download
    @parser.html = @scraper.body(use: "hammer", url: "#{URL}#{PATH}", sleep: 5)
    @parser.menu_links(URL)&.each do |menu_link|
      @parser.html = @scraper.body(use: "hammer", url: menu_link, sleep: 5)
      @parser.years_paths&.each do |path|
        @parser.html = @scraper.body(use: "hammer", url: "#{menu_link}#{path}", sleep: 5)
        titles_data = @parser.parse_titles
        titles_data.each do |title_data|
          md5 = to_md5(title_data)
          save_html(@parser.html, "_page_#{md5}.html", md5)
        end
        links = @parser.article_links
        next if links.nil?
        article_data = []
        links.each do |url|
          @parser.html = @scraper.body(use: "hammer", url: url, sleep: 5)
          data = @parser.parse_article
          md5 = to_md5(data)
          save_html(@parser.html, "_article_#{md5}.html", md5)
          article_data << data
        end
        titles_data.each_with_index do |_,i|
          iter_data = titles_data[i].merge(article_data[i])
          @keeper.store(iter_data)
        end
      end
    end
  end

  def to_md5(var)
    md5 = ''
    md5 = Digest::MD5.hexdigest var if var.is_a?(String)
    md5 = Digest::MD5.hexdigest var.join if var.is_a?(Array)
    md5 = Digest::MD5.hexdigest var.values.join if var.is_a?(Hash)
    md5
  end

  def save_html(html, filename, md5_sum)
    peon.put(content: html.to_html.to_s, file: filename) unless peon.give_list.include?(md5_sum) || html.blank?
  end
end
