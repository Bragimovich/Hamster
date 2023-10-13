# frozen_string_literal: true

require_relative '../models/us_dept_ways_and_means'
require_relative '../models/us_dept_ways_and_means_runs'
require 'scylla'

class UsDeptWaysAndMeansScraper < Hamster::Scraper

  SOURCE = 'https://waysandmeans.house.gov'
  TEN_MINUTES = 600
  EXCEPTIONS = [
    'https://waysandmeans.house.gov/media-center/press-releases/chairman-pascrell-announces-oversight-subcommittee-hearing-examining'
  ]

  def initialize
    super
    @all_stored = false
    @page_link = ''
  end

  def start
    download
    p 'scrape finished'
  rescue StandardError => e
    p 'inside outer rescue'
    p e
    Hamster.report(to: 'eldar.mustafaiev', message: "Project # 0271 --download: Error - \n#{e}, went to sleep for 10 min", use: :both)
    sleep(TEN_MINUTES)
  end

  private

  def download
    mark_as_started

    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }

    parse_news_pages

    mark_as_finished
  end

  def parse_news_pages
    page_num = 0
    loop do
      begin
        @page_link = SOURCE + '/media-center/press-releases?page=' + page_num.to_s
        page = connect_to(@page_link, proxy_filter: @filter, ssl_verify: false)&.body
        parse_page(page)
        return if @all_stored
        page_num += 1
      rescue StandardError => e
        p e
        p e.full_message
      end
    end
  end

  def parse_page(page)
    news = Nokogiri::HTML(page).css('.view-congress-press-releases .views-row')
    @all_stored = news.empty?
    return if @all_stored
    news.each do |press_release|
      next if press_release.nil?
      article_link = SOURCE + press_release.css('.views-field-title a').first['href']
      if UsDeptWaysAndMeans.exists?(link: article_link)
        next if EXCEPTIONS.include? article_link
        @all_stored = true
        return
      end
      parse_press_release(press_release)
    end
  end

  def parse_press_release(press_release)

    article_link = SOURCE + press_release.css('.views-field-title a').first['href']
    article_subtitle, article_body = parse_article(article_link)
    article_teaser = parse_teaser_from_article(article_body)

    us_dept_ways_and_means = UsDeptWaysAndMeans.new

    us_dept_ways_and_means.title = press_release.css('.views-field-title a').text.strip
    us_dept_ways_and_means.subtitle = article_subtitle
    us_dept_ways_and_means.teaser = article_teaser
    us_dept_ways_and_means.article = article_body
    us_dept_ways_and_means.link = article_link
    us_dept_ways_and_means.date = press_release.css('.views-field-created .field-content').text
    us_dept_ways_and_means.dirty_news = article_body.blank? or article_body.text.blank? or (article_body.text.language != "english")
    us_dept_ways_and_means.with_table = article_body.css('table').present?
    us_dept_ways_and_means.data_source_url = @page_link

    us_dept_ways_and_means.save

  rescue StandardError => e
    p e
    p e.full_message
    Hamster.report(to: 'eldar.mustafaiev', message: "Project # 0271 ::parse_press_release : Error - \n#{@page_link}\n#{article_link}\n#{e}", use: :both)
  end

  def parse_article(link)
    page = connect_to(link, proxy_filter: @filter, ssl_verify: false)&.body
    body = Nokogiri::HTML(page).css('.panel-panel')
    article = body.css('.field-name-body')
    subtitle = body.css('.field-name-field-congress-subtitle').text.strip
    return subtitle, article
  end

  def parse_teaser_from_article(body)
    items = body.at('.field-item').elements
    teaser = ''
    items.each do |item|
      # next if item.name == "table"
      # binding.pry
      teaser_candidate = item.text
      teaser_candidate =  parse_multiline_text(teaser_candidate) if teaser_candidate.include? "\n"
      teaser = teaser_candidate if teaser_candidate.length > teaser.length
      break if teaser.length >= 50
    end
    teaser = teaser.gsub(/\A[[:space:]]+|[[:space:]]+\z/, '')
    teaser = TeaserCorrector.new(teaser).correct
    teaser.strip
  end

  def parse_multiline_text(multi_liner)
    # binding.pry
    one_liner = multi_liner.split("\n").compact_blank.join('. ')
    one_liner.gsub(/[[:space:]]+/, ' ')
  rescue StandardError => e
    ''
  end

  def mark_as_started
    UsDeptWaysAndMeansRuns.create
    last_run = UsDeptWaysAndMeansRuns.last
    UsDeptWaysAndMeansRuns.find(last_run.id).update(status: 'download started')
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end
    response
  end

  def mark_as_finished
    last_run = UsDeptWaysAndMeansRuns.last
    UsDeptWaysAndMeansRuns.find(last_run.id).update(status: 'download finished')
  end

end
