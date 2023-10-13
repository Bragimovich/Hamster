require_relative '../lib/keeper'
require_relative '../lib/project_parser'
require_relative '../lib/scraper'
require_relative '../lib/converter'
require_relative '../models//ustr'
require_relative '../models//ustr_runs'

class Manager < Hamster::Harvester

  URL = 'https://ustr.gov/about-us/policy-offices/press-office/news'
  PR_URL = 'https://ustr.gov/about-us/policy-offices/press-office/ustr-archives/2007-2021-press-releases'
  FS_ARCH_URL = 'https://ustr.gov/about-us/policy-offices/press-office/ustr-archives/2007-2020-fact-sheets'

  def initialize(**params)
    super
    @runs = RunId.new(Ustr_runs)
    @run_id = @runs.run_id
    @keeper = Keeper.new(Ustr, @run_id)
    @scraper = Scraper.new
    @parser = ProjectParser.new
    @converter = Converter.new
  end

  def download
    save_news
    save_fact_sheets
    save_ustr_archives
    on_finish
  end

  def save_news
    @parser.html = @scraper.body(use: 'hammer', url: URL)
    if @parser.last_link.nil? || @parser.next_link.nil?
      @parser.pages_links.each do |url|
        save_data(url, 1, "news")
      end
    else
      last_link = @parser.last_link
      until @parser.last_link.nil?
        save_data(URL, 1, "news")
        url = @parser.next_link

        break  if url.blank?

        @parser.html = @scraper.body(use: "hammer", url: url)
      end
      if last_link == @parser.next_link
        save_data(last_link, 1, "news")
      end
    end
  end

  def save_fact_sheets
    fs_url = 'https://ustr.gov/about-us/policy-offices/press-office/fact-sheets'
    @parser.html = @scraper.body(use: 'hammer', url: fs_url)
    @parser.years_fs_links.each do |url|
      save_data(url, 2, "factsheets")
    end
  end

  def save_ustr_archives
    @parser.html = @scraper.body(use: 'hammer', url: PR_URL)
    @parser.years_archive_links.each do |url|
      save_data(url, 2, "ustr_archives_press_releases")
    end
    @parser.html = @scraper.body(use: 'hammer', url: FS_ARCH_URL)
    @parser.years_archive_links.each do |url|
      save_data(url, 2, "ustr_archives_fact_sheets")
    end
  end

  def save_data(url, menu_index, from)
    @parser.html = @scraper.body(use: 'hammer', url: url)
    titles = @parser.fs_titles_data if menu_index == 2
    titles = @parser.titles_data if menu_index == 1

    return if titles.blank?

    titles.each do |data|
      md5 = @converter.to_md5(data)
      filename = "#{from}_page_#{md5}.html"
      save_html(@parser.html, filename, md5)
    end

    articles = []
    @parser.article_links.each do |url|
      @parser.html = @scraper.body(use: 'hammer', url: url)
      article_data = @parser.article_data
      md5 = @converter.to_md5(article_data)
      filename = "#{from}_article_#{md5}.html"
      save_html(@parser.html, filename, md5)
      articles << article_data
    end

    return if articles.blank?

    titles.each_with_index do |_, i|
      data = titles[i].merge(articles[i])
      @keeper.store(data)
    end
  end

  def save_html(html, filename, md5_sum)
    peon.put(content: html.to_html.to_s, file: filename) unless peon.give_list.include?(md5_sum) || html.blank?
  end

  def on_finish
    @keeper.update_touched_run_id(@run_id)
    @keeper.update_deleted(@run_id)
    @runs.finish
  end
end
