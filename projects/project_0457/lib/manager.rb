require_relative '../lib/keeper'
require_relative '../lib/project_parser'
require_relative '../lib/scraper'
require_relative '../models//nyshcr'
require_relative '../models//nyshcr_runs'

class Manager < Hamster::Harvester

  URL = "https://hcr.ny.gov/pressroom?q=/pressroom%3Fq%3D/pressroom&f%5B0%5D=filter_term%3A2091"

  def initialize(**params)
    super
    @scraper_name = 'vyacheslav pospelov'
    @scraper = Scraper.new
    @scraper.safe_connection {
      @runs = RunId.new(Nyshcr_runs)
      @run_id = @runs.run_id
    }
    @keeper = Keeper.new(Nyshcr, @run_id)
    @keeper.destroy_where(id: 653)
    #@keeper.fix_empty_touched_run_id
    #@keeper.fix_wrong_md5
    @parser = ProjectParser.new(@run_id)
    @converter = Converter.new(@run_id)
  end

  def download
    @parser.browser = @scraper.body(use: "hammer", url: URL, sleep: 15, expected_css: 'div.news-listing-date')
    unless @parser.last_link.nil? || @parser.next_link.nil?
      last_link = @parser.last_link
      save_data(URL)
      until @parser.next_link.nil?
        url = @parser.next_link
        save_data(url)
      end
      save_data(last_link)
    end
    on_finish
  end

  def save_data(url)
    #puts "url = #{url}".red
    html = @scraper.body(use: "hammer", url: url, sleep: 15, expected_css: 'div.news-listing-date')
    navigation_body = html.body
    #puts "html body = #{html.body}".red
    @parser.browser = html
    #puts "@parser.html = #{@parser.html}".yellow
    titles_data = @parser.titles_data
    titles_data.each do |title_data|
      md5 = @converter.to_md5(title_data)
      save_html(@parser.html, "page_#{md5}.html", md5, true)
      link = title_data[:link]
      @parser.browser = @scraper.body(use: "hammer", url: link, sleep: 15, expected_css: 'div.news-body div.press-body')
      article_data = @parser.article_data
      article_data.except!(:teaser) unless title_data[:teaser].blank?
      data = title_data.merge(article_data)
      next if !data.is_a?(Hash) || data[:title].blank?
      md5 = @converter.to_md5(data)
      data.merge!(md5_hash: md5, run_id: @run_id)
      save_html(@parser.html, "article_#{md5}.html", md5, true)
      @keeper.upsert_all(data) if @keeper.safe_operation { Nyshcr.find_by(link: data[:link]).nil? }
    end
    @parser.html = navigation_body
  end

  def save_html(html, filename, md5_sum, is_browser = false)
    peon.put(content: html.to_html.to_s, file: filename) unless peon.give_list.include?(md5_sum) || html.blank?
  end

  def on_finish
    @keeper.update_touched_run_id
    @keeper.update_deleted
    @runs.finish
  end
end
