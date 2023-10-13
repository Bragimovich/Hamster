# frozen_string_literal: true

require_relative '../models/us_dept_bureau_of_political_military_affairs'
require_relative '../models/us_dept_bureau_of_political_military_affairs_runs'
require_relative '../models/us_dept_bureau_of_political_military_affairs_tags'
require_relative '../models/us_dept_bureau_of_political_military_affairs_tags_article_links'

require 'scylla'

class UsDeptPmBureauParser < Hamster::Parser

  SOURCE = 'https://www.state.gov/bureau-of-political-military-affairs-releases/'
  IDX_SUB_FOLDER = 'indexes/'
  PR_SUB_FOLDER = 'press_releases/'

  def initialize
    super
    @all_stored = false
    @run_id = nil
  end

  def start
    send_to_slack("Task #0332 - store started")
    mark_as_started

    store

    mark_as_finished
    send_to_slack("Task #0332 - store finished")
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0332_error in start:\n#{e.inspect}")
  end

  private

  def store
    init_tags
    parse_idx_pages
  end

  def init_tags
    @issue_tag = {}
    UsDeptBureauOfPoliticalMilitaryAffairsTags.find_each.each do |issue|
      @issue_tag[issue.tag] = issue.id
    end
  rescue => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0332_error in init_tags:\n#{e.inspect}")
    raise
  end

  def parse_idx_pages
    files = peon.give_list(subfolder: IDX_SUB_FOLDER).sort.reverse!
    new_articles = peon.give_list(subfolder: PR_SUB_FOLDER).to_set
    loop do
      break if files.empty?
      idx_file = files.pop
      parse_page(idx_file, new_articles)
      return if @all_stored
    rescue StandardError => e
      print_all e, e.full_message, title: " ERROR "
      send_to_slack("project_0332_error in parse_idx_pages:\n#{e.inspect}")
    end
  end

  def parse_page(idx_file, new_articles)
    file_content = peon.give(subfolder: IDX_SUB_FOLDER, file: idx_file)
    news = Nokogiri::HTML(file_content).css('#content .collection-list li')
    return if (@all_stored = news.empty?)
    news.each_with_index do |article_summary, idx|
      next if article_summary.nil?
      article_filename = idx_file.gsub('.', "_#{idx.to_s.rjust(2, "0")}.")
      next unless new_articles.include? article_filename
      page_num = idx_file.gsub('.gz', '').split("_")[1].to_i
      parse_press_release(article_summary, article_filename, page_num)
    end
  end

  def parse_press_release(article_summary, article_filename, page_num)
    article_link = article_summary.css('a').first['href']
    article_body = parse_article(article_filename, article_link)
    article_teaser = parse_teaser_from_article(article_body)
    title = article_summary.at('a').text.strip
    article_title = title.size <= 205 ? title : (title[0, title.rindex(/\s/, 202)].rstrip + '...')

    us_dept_pm_bureau = UsDeptBureauOfPoliticalMilitaryAffairs.new

    us_dept_pm_bureau.title = article_title
    us_dept_pm_bureau.teaser = article_teaser
    us_dept_pm_bureau.article = article_body
    us_dept_pm_bureau.link = article_link
    us_dept_pm_bureau.type = article_summary.at('p')&.text&.strip&.downcase
    us_dept_pm_bureau.date = article_summary.at('.collection-result-meta span[dir="ltr"]')&.text
    us_dept_pm_bureau.dirty_news = article_body.blank? || article_body.text.blank? || (article_body.text.language != "english")
    us_dept_pm_bureau.with_table = article_body.css('table').present?
    us_dept_pm_bureau.data_source_url = SOURCE + "page/#{page_num.to_s}/"

    us_dept_pm_bureau.save

  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0332_error in parse_press_release:\n#{article_link}\n#{e.inspect}")
  end

  def parse_article(file, link)
    file_content = peon.give(subfolder: PR_SUB_FOLDER, file: file)
    page_content = Nokogiri::HTML(file_content).at('article')
    parse_article_tags(page_content, link)
    article = page_content&.at('.entry-content')
    article
  end

  def parse_article_tags(content, link)
    tags = content.css('.row .related-tags__pills a')
    tags.each do |tag|
      tag_text = tag&.text&.strip&.downcase
      unless @issue_tag.key?(tag_text)
        us_dept_bureau_of_political_military_affairs_tags = UsDeptBureauOfPoliticalMilitaryAffairsTags.new
        us_dept_bureau_of_political_military_affairs_tags.tag = tag_text
        us_dept_bureau_of_political_military_affairs_tags.save
        @issue_tag[tag_text] = UsDeptBureauOfPoliticalMilitaryAffairsTags.last.id
      end
      next if UsDeptBureauOfPoliticalMilitaryAffairsTagsArticleLinks.exists?(article_link: link, tag_id: @issue_tag[tag_text])
      us_dept_bureau_of_political_military_affairs_tags_article_links = UsDeptBureauOfPoliticalMilitaryAffairsTagsArticleLinks.new
      us_dept_bureau_of_political_military_affairs_tags_article_links.article_link = link
      us_dept_bureau_of_political_military_affairs_tags_article_links.tag_id = @issue_tag[tag_text] #strip
      us_dept_bureau_of_political_military_affairs_tags_article_links.save
    end
  end

  def parse_teaser_from_article(body)
    return if body.to_s.strip.empty?
    items = body.elements
    teaser = ''
    items.each do |item|
      # next if item.name == "table"
      next if item.name == "script"
      teaser_candidate = item.text
      teaser_candidate = parse_multiline_text(teaser_candidate) if teaser_candidate.include? "\n"
      teaser = teaser_candidate if teaser_candidate.length > teaser.length
      break if teaser.length >= 50
    end
    teaser = teaser.gsub(/\A[[:space:]]+|[[:space:]]+\z/, '')
    teaser = TeaserCorrector.new(teaser).correct
    teaser.strip
  end

  def parse_multiline_text(multi_liner)
    one_liner = multi_liner.split("\n").compact_blank.join('. ')
    one_liner.gsub(/[[:space:]]+/, ' ')
  end

  def mark_as_started
    last_run = UsDeptBureauOfPoliticalMilitaryAffairsRuns.last
    if last_run.status == 'download finished'
      last_run.update(status: 'store started')
      @run_id = last_run.id
      puts "#{"="*50} store started #{"="*50}"
    else
      puts 'Cannot start store process'
      puts 'Download is not finished correctly. Exiting...'
      raise "Error: Download not finished"
    end
  end

  def mark_as_finished
    UsDeptBureauOfPoliticalMilitaryAffairsRuns.find(@run_id).update(status: 'finished')
    puts "#{"="*50} store finished #{"="*50}"
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
