# frozen_string_literal: true

require_relative '../models/us_dept_bureau_of_political_military_affairs_runs'

class UsDeptPmBureauScraper < Hamster::Scraper

  SOURCE = 'https://www.state.gov/bureau-of-political-military-affairs-releases/'
  IDX_SUB_FOLDER = 'indexes/'
  PR_SUB_FOLDER = 'press_releases/'
  IMPROPER_LINKS = [
    "https://2009-2017.state.gov/f/evaluations/all/245666.htm",
    ""
  ]

  def initialize
    super
    @all_stored = false
    @run_id = nil
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def start
    send_to_slack("Task #0332 - download started")
    mark_as_started

    download

    mark_as_finished
    send_to_slack("Task #0332 - download finished")
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0332_error in start:\n#{e.inspect}")
  end

  private

  def download
    tar_store_to_trash
    save_index_pages
  end

  def save_index_pages
    ignored_article_links = collect_stored_article_links.merge(IMPROPER_LINKS)
    page_num = 1
    loop do
      page_link = page_num == 1 ? SOURCE : SOURCE + "page/#{page_num.to_s}/"
      page = connect_to(page_link, proxy_filter: @filter, ssl_verify: false)&.body
      save_page(page, page_num, ignored_article_links)
      return if @all_stored
      page_num += 1
    rescue StandardError => e
      print_all e, e.full_message, title: " ERROR "
      send_to_slack("project_0332_error in save_index_pages:\nPage number - #{page_num}\n#{e.inspect}")
    end
  end

  def save_page(page, page_num, ignored_article_links)
    news = Nokogiri::HTML(page).css('#content .collection-list li')
    return if (@all_stored = news.empty?)

    index_file_name = "#{@run_id}_#{page_num.to_s.rjust(2, "0")}"
    save_file(page, index_file_name, IDX_SUB_FOLDER)

    news.each_with_index do |press_release, idx|
      next if press_release.nil?
      article_link = press_release.css('a').first['href']
      next if ignored_article_links.include?(article_link) # article_link.to_s.strip.empty? - nil and empty cases
      save_press_release(article_link, page_num, idx)
    end
  end

  def save_press_release(article_link, page_num, row_num)
    page = connect_to(article_link, proxy_filter: @filter, ssl_verify: false)&.body
    article_file_name = "#{@run_id}_#{page_num.to_s.rjust(2, "0")}_#{row_num.to_s.rjust(2, "0")}"
    save_file(page, article_file_name, PR_SUB_FOLDER)
  rescue StandardError => e
    if article_link.include? '/people/'
      article_link.gsub!('/people/', '/biographies/')
      retry
    end
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0332_error in save_press_release:\n#{article_link}\n#{e.inspect}")
  end

  def collect_stored_article_links()
    UsDeptBureauOfPoliticalMilitaryAffairs.pluck(:link).to_set
  end

  def tar_store_to_trash
    prev_run_id = @run_id.to_i - 1
    run_name_justified = prev_run_id.to_s.rjust(4, "0")
    tar_file = "#{run_name_justified}.tar"
    src_dir = "#{@_storehouse_}store/"
    dest_dir = "#{@_storehouse_}trash/"
    Minitar.pack(src_dir, File.open("#{dest_dir}#{tar_file}", 'wb'))
    FileUtils.rm_r Dir.glob("#{src_dir}*")
  end

  def save_file(html, name, folder)
    peon.put content: html, file: name, subfolder: folder
  end

  def connect_to(*arguments, &block)
    response = nil
    3.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end
    response
  end

  def mark_as_started
    current_run = UsDeptBureauOfPoliticalMilitaryAffairsRuns.create(status: 'download started')
    @run_id = current_run.id
    puts "#{"=" * 50} download started #{"=" * 50}"
  end

  def mark_as_finished
    UsDeptBureauOfPoliticalMilitaryAffairsRuns.find(@run_id).update(status: 'download finished')
    puts "#{"=" * 50} download finished #{"=" * 50}"
  end

  def print_all(*args, title: nil, line_feed: true)
    puts "#{"=" * 50}#{title}#{"=" * 50}" if title
    puts args
    puts if line_feed
  end

  def send_to_slack(message)
    Hamster.report(to: 'U031HSK8TGF', message: message)
  end

end
