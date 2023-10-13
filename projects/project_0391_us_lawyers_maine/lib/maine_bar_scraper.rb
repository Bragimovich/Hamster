# frozen_string_literal: true

require_relative '../models/maine_bar_runs'

class MaineBarScraper < Hamster::Scraper

  # SOURCE = 'https://www1.maine.gov/cgi-bin/online/maine_bar/'
  SOURCE = 'https://apps.web.maine.gov/cgi-bin/online/maine_bar/'
  PAGE_LIMIT = 250
  TRY_LIMIT = 4

  def initialize
    super
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @run_id = nil
    @finished = false
  end

  def start
    send_to_slack "Project #0391 download started"
    log_download_started

    download

    log_download_finished
    send_to_slack "Project #0391 download finished"
  rescue => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack "project_0391 error in start:\n#{e.inspect}"
  end

  private

  def download
    index_num = 1
    loop do
      index_raw = download_index(index_num)
      save_index(index_raw, index_num)
      download_index_items(index_raw, index_num)
      return if @finished
      index_num += 1
    end
  rescue => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack "project_0391 error in download:\n#{e.inspect}"
  end

  def download_index(index_num)
    try ||= 0
    index_url = SOURCE + "attorney_directory_results.pl?page=#{index_num}"
    index_raw = connect_to(index_url, proxy_filter: @filter, ssl_verify: false)&.body
    raise if ( no_results_error(index_raw) && (index_num < PAGE_LIMIT) )
    index_raw
  rescue => e
    if try < TRY_LIMIT
      try += 1
      sleep 10 ** try
      retry
    end
    print_all e, e.full_message, title: " ERROR "
    send_to_slack "project_0391 error in download_index:\n#{e.inspect}"
    raise
  end

  def save_index(index_raw, index_num)
    file_name = 'index_' + index_num.to_s.rjust(3, "0")
    index_folder = @run_id.to_s.rjust(4, "0") + '_indexes'
    save_file(index_raw, file_name, index_folder)
  end

  def download_index_items(page, index_num)
    return if (@finished = no_results_error(page))
    records = Nokogiri::HTML(page).at('#maincontent1 table tbody').css('tr')
    records.each_with_index do |record, idx|
      next if record.nil?
      download_record(record, index_num, idx)
    end
  end

  def download_record(record, index_page, record_num)
    page_link = SOURCE + record.at('td a')['href']
    page = connect_to(page_link, proxy_filter: @filter, ssl_verify: false)&.body
    file_name = "#{index_page.to_s.rjust(3, "0")}_#{record_num.to_s.rjust(2, "0")}"
    records_folder = @run_id.to_s.rjust(4, "0") + '_index_' + index_page.to_s.rjust(3, "0")
    # binding.pry
    save_file(page, file_name, records_folder)
  rescue => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack "project_0391 error in download_record:\n#{e.inspect}"
  end

  def no_results_error(page)
    Nokogiri::HTML(page).at('#maincontent1 table tbody')&.at('tr')&.at('p')&.attr('class') == 'error'
  end

  def save_file(html, name, folder)
    peon.put content: html, file: name, subfolder: folder
  end

  def log_download_started
    @run_id = MaineBarRuns.create(status: 'download started').id
    puts "#{"="*50} download started #{"="*50}"
  end

  def connect_to(*arguments, &block)
    response = nil
    3.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end
    response
  end

  def log_download_finished
    MaineBarRuns.find(@run_id).update(status: 'download finished')
    puts "#{"="*50} download finished #{"="*50}"
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
