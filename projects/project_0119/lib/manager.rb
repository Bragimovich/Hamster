require_relative '../lib/keeper'
require_relative '../lib/project_parser'
require_relative '../lib/scraper'
require_relative '../lib/converter'
require_relative '../models/nsf'
require_relative '../models/nsf_runs'

class Manager < Hamster::Harvester
  SOURCE = 'https://beta.nsf.gov'
  SUB_PATH = '/news/releases?search_api_fulltext=&sort_bef_combine=published_at_DESC&sort_by=published_at&sort_order=DESC&page='
  PAGES_FOLDER = 'nsf_pages/'
  ARTICLE_FOLDER = 'nsf_article/'

  def initialize(**params)
    super
    @scraper = Scraper.new
    #@scraper.safe_connection {
      @runs = RunId.new(NSFRuns)
      @run_id = @runs.run_id
    #}
    @keeper = Keeper.new(NSF, @run_id)
    @parser = Project_Parser.new
    @converter = Converter.new
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def download
    @all_stored = false
    links = report_links
    save_articles(links)
    store
    on_finish
  end

  def save_articles(links)
    links.each do |link|
      next if link == "https://beta.nsf.gov/news/releases"

      next unless NSF.find_by(link: link).nil? #@keeper.safe_operation { NSF.find_by(link: link).nil? }

      @parser.html = @scraper.body(url: link, use: 'hammer', proxy_filter: @filter)
      md5 = @converter.to_md5(@parser.html.to_s)
      save_file(@parser.html, "acticle_#{md5}.html", md5, ARTICLE_FOLDER)
    end
  end

  def report_links
    @parser.html = @scraper.body(url: "#{SOURCE}#{SUB_PATH}0", use: 'hammer', proxy_filter: @filter)
    (0..@parser.pages_amount).map { |number|
      @parser.html = @scraper.body(url: "#{SOURCE}#{SUB_PATH}#{number}", use: 'hammer', proxy_filter: @filter)
      md5 = @converter.to_md5(@parser.html.to_s)
      save_file(@parser.html, "page_#{md5}.html", md5, PAGES_FOLDER)
      @parser.filtered_links
    }.flatten
  end

  def store
    files = peon.give_list(subfolder: ARTICLE_FOLDER)
    loop do
      break if files.empty?

      @parser.html = peon.give(subfolder: ARTICLE_FOLDER, file: files.pop)
      data = @parser.article_data

      next if data.blank?

      next if data[:link] == "https://beta.nsf.gov/news/releases"

      @keeper.insert_all(data) if NSF.find_by(teaser: data[:teaser], date: data[:date]).nil? #@keeper.safe_operation { NSF.find_by(teaser: data[:teaser], date: data[:date]).nil? }
    end
  end

  def save_file(html, filename, md5_sum = nil, subfolder = nil)
    condition = html.blank?
    condition = peon.give_list.include?(md5_sum) || html.blank? if md5_sum
    data = {
      content: html.to_html.to_s,
      file: filename
    }
    data.merge!(subfolder: subfolder) if subfolder
    peon.put(data) unless condition
  end

  def clean_dir(path)
    FileUtils.rm_rf("#{path}/.", secure: true)
  end

  def on_finish
    @keeper.update_deleted
    clean_dir("#{storehouse}store")
    clean_dir("#{storehouse}trash")
    @runs.finish
  end
end
