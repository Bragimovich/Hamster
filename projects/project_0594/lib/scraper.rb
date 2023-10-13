# frozen_string_literal: true
require_relative '../models/co_saac_case_run'
require_relative '../lib/keeper'

class Scraper < Hamster::Scraper
  
  SOURCE = "https://www.courts.state.co.us"
  INFO_FOLDER = "info_co_saac_case_us"
  ACTIVITY_FOLDER = "activity_co_saac_case_us"
  
  def initialize(*_)
    super
    @keeper = Keeper.new
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @update = nil
  end
  
  def start(update)
    @keeper = Keeper.new
    log_download_started

    @update = update
    download

    log_download_finished
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0594 error in start:\n#{e.inspect}")
  end
  
  def download_pdfs(link, folder)
    save_pdfs(link, folder)
  end
  
  private
  
  def download
    source_link = SOURCE + "/Courts/Court_Of_Appeals/Case_Announcements/Index.cfm"
    element_list_year = get_list_year(source_link)
    list_year = []
    element_list_year.map do |item|
      list_year << item.text
    end
    list_year.each do |year|
      url = SOURCE + "/Courts/Court_Of_Appeals/Case_Announcements/Index.cfm?year=#{year}&month=&Submit=Go"
      page = load_web_resource(url)&.body
      list_link = get_pdf_link(page)
      list_link.map do |link|
        link = link.to_s.gsub("\ ", "%20")
        binding.pry
        save_pdfs(link, INFO_FOLDER) unless link.nil?
      rescue
        next
      end
    end
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0594 error in download:\n#{e.inspect}")
  end

  def save_pdfs(link, folder)
    link_find = connect_to(url: link)
    return if link_find.blank?
    if link_find.status == 302
      link = link_find.headers['Request URL'].to_s.strip
    end
    name = nil
    unless link_find.body.blank?
      cobble = Dasher.new(:using=>:cobble)
      pdf_file = cobble.get(link)
      name = ecrypt_name(link)
      unless pdf_file.blank?
        peon.put(file: name, subfolder: folder, content: pdf_file)
      end
    end
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0594 error in save_pdfs:\n#{e.inspect}")
  end
  
  def ecrypt_name(link)
    convert_link = link.to_s.gsub("%20", "_20")
    convert_link = convert_link.to_s.gsub("/", "__")
    convert_link = convert_link.to_s.gsub(":", "")
    convert_link = convert_link.to_s.gsub("(", "_F_")
    convert_link = convert_link.to_s.gsub(")", "_B_")
    extension = link.split("\.").last
    gen_name = convert_link.to_s + "_____" + Digest::MD5.hexdigest(link).to_s + "." + extension
    gen_name
  end

  def get_list_year(link)
    html = load_web_resource(link)&.body
    doc = Nokogiri::HTML.parse(html)
    option_css_selector = '#year > option'
    doc.css(option_css_selector)
  end

  def get_pdf_link(html)
    doc = Nokogiri::HTML.parse(html)
    pdf_link_css_selector = '#main-content > div.wrapper-full > div.center-content-left > a @href'
    doc.css(pdf_link_css_selector)
  end

  def log_download_started
    @keeper.create_status('download started')
    Hamster.logger.debug "#{"="*50} download started #{"="*50}"
  end

  def log_download_finished
    @keeper.update_status('download finished')
    Hamster.logger.debug "#{"="*50} download finished #{"="*50}"
  end

  def send_to_slack(message)
    Hamster.report(to: 'Robert Arnold', message: message , use: :slack)
  end

  def print_all(*args, title: nil, line_feed: true)
    Hamster.logger.debug "#{"=" * 50}#{title}#{"=" * 50}" if title
    Hamster.logger.debug args
    Hamster.logger.debug "\n" if line_feed
  end

  def load_web_resource(url)
    attempts ||= 1
    connect_to(url, proxy_filter: @filter, ssl_verify: false)
  rescue StandardError => e
    if (attempts += 1) <= 3
      sleep 8**attempts
      Hamster.logger.error "<Attempt #{attempts}: retrying ...>"
      retry
    end
    Hamster.logger.error "Retry attempts exceeded."
    send_to_slack("project_0594 error in load_web_resource:\n#{e.inspect}")
    raise
  end

end