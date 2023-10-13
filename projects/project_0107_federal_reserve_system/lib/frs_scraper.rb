# frozen_string_literal: true

require 'yaml'
require_relative '../models/us_dept_frs'

class FRSScraper < Hamster::Scraper
  SOURCE = 'https://www.federalreserve.gov'
  PR_PATH = '/newsevents/pressreleases.htm'
  SPEECHES_PATH = '/newsevents/speeches.htm'
  TESTIMONY_PATH = '/newsevents/testimony.htm'
  PATHES = [PR_PATH, SPEECHES_PATH, TESTIMONY_PATH]
  SUB_FOLDER = 'federal_reserve_system/'

  def initialize
    @all_rows = []
    @sub_path = ""
    @i = 0
    super
  end

  def start
    begin
      download
    rescue => e
      [STARS,  e].each {|line| logger.fatal(line)}
      Hamster.report(to: OLEKSII_KUTS, message: "Project # 0107 --download: Error - \n#{e}", use: :slack)
    end
  end

  private

  def download
    mark_as_started
    filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    PATHES[0..-1].each do |sub_path|
      @sub_path = sub_path
      main_page = get_main_page(filter)
      year_links = get_year_links(main_page)
      year_links.each do |year_link|
        begin
          rows = get_rows(year_link, filter)
          add_to_all_rows(rows)
          links = get_links(rows)
          save_pages(links, filter)
        rescue StandardError => e
          [STARS,  e].each {|line| logger.fatal(line)}
          Hamster.report(to: OLEKSII_KUTS, message: "Project # 0107 --download: Error - \n#{e}", use: :slack)
        end
      end
      write_to_yaml
    end
    mark_as_finished
  end

  def add_to_all_rows(rows)
    rows.each do |r|
      @all_rows.push(r)
    end
  end

  def get_links(rows)
    links = rows.map{|h| h.values.first.first}
    links = remove_links_from_other_websites(links)
    links
  end

  def remove_links_from_other_websites(links)
    links.filter{|link| link.scan('http').size == 1}
  end

  def mark_as_started
    UsDeptFrsRuns.create
    last_run = UsDeptFrsRuns.last
    UsDeptFrsRuns.find(last_run.id).update(status: 'download started')
  end

  def mark_as_finished
    last_run = UsDeptFrsRuns.last
    UsDeptFrsRuns.find(last_run.id).update(status: 'download finished')
  end

  def get_main_page(filter)
    connect_to(SOURCE + @sub_path, proxy_filter: filter)&.body
  end

  def get_year_links(main_page)
    @document = Nokogiri::HTML(main_page)
    ul = @document.css('.list-unstyled.panel-body__list').css('a')
    year_links = ul.map do |a| a['href'] end
    year_links.pop # remove archive link
    res = year_links[0..1] # year_links =  [year_links[0], year_links[1]]

    current_year = Date.today.year.to_s
    res[0].include?(current_year) ? res : increment_link_year(res)
  end

  def increment_link_year(links)
    links.map do |el|
      year = el.split('-')[0].split('/')[-1].to_i
      el.sub("#{year}", "#{year.succ}")
    end
  end

  def get_rows(l, filter)
    year_page = connect_to(SOURCE + l , proxy_filter: filter)&.body
    year_doc = Nokogiri::HTML(year_page)
    events = year_doc.css('.row.eventlist').first.css('.row')
    events.map do |event|
      {
          event.css('.eventlist__event').css('a').first['href'].split('/').last => [
              SOURCE + event.css('.eventlist__event').css('a').first['href'],
              event.css('.eventlist__event').css('a').first.text,

              @sub_path.eql?(PR_PATH) ?
                event.css('.eventlist__event').css('.eventlist__press').css('strong').last.text :
                event.css('.eventlist__event').css('.news__speaker').last.text,

              event.css('.eventlist__time').css('time').last.text
          ]
      }
    end
  rescue
    return [] #if something went wrong, just return empty list of
  end

  def write_to_yaml
    Dir.mkdir("#{ENV['HOME']}/HarvestStorehouse/project_0107/store/yaml") unless File.exists?(
        "#{ENV['HOME']}/HarvestStorehouse/project_0107/store/yaml"
    )
    yaml_storage_path = "#{ENV['HOME']}/HarvestStorehouse/project_0107/store/yaml/rows.yml"

    File.write(yaml_storage_path, @all_rows.to_yaml)
  end

  def save_pages(links, filter)
    links.each do |l|
      new_link = UsDeptFrs.find_by(link: l).nil?
      next unless new_link
      begin
        page = connect_to(l , proxy_filter: filter)&.body
        save_file(page, l)
      rescue StandardError => e
        pp e, e.full_message
      end
    end
  end

  def save_file(html, l)
    name = l.split('/').last
    peon.put content: html, file: "#{name}", subfolder: SUB_FOLDER
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304].include?(response.status)
    end

    response
  end

end
