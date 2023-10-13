# frozen_string_literal: true

require_relative '../models/midland_county_covid_cases_biweekly_reports'
require_relative '../models/midland_county_covid_cases_biweekly_reports_info'
require_relative '../models/midland_county_covid_cases_biweekly_reports_runs'

class Scraper < Hamster::Harvester

  def initialize
    super
    @md5 = Digest::MD5
    @proxy_filter = ProxyFilter.new(duration: 1.hours, touches: 500)
  end

  SOURCE_LINK = 'https://www.midlandtexas.gov/978/Midland-County-COVID-19-Report'

  def main
    begin
      @script_start = Time.now
      assign_new_run
      @run_id = (MidlandCountyCovidCasesRuns.maximum(:id).nil? ? 1 : MidlandCountyCovidCasesRuns.maximum(:id))
      @last_scrape_date = Date.today.to_s
      @next_scrape_date = (Date.today + 14).to_s
      get_source_page
      parse_data
      Hamster.report to: 'URYM6LD9V', message: "The script completed successfully at #{Time.now}"
    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      Hamster.report to: 'URYM6LD9V', message: "The script fall with error at #{Time.now}: \n#{e} | #{e.backtrace}"
    end
  end

  private

  def get_page(host, link)
    begin
      request = Hamster.connect_to(
        url: link,
        headers: {
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
          'Sec-Fetch-Mode' => 'navigate',
          'Host' => host
        },
        proxy_filter: @proxy_filter,
        method: :get
      )
      raise if request&.headers.nil?

    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      sleep(rand(5..10))
      if  (@script_start + 1000) < Time.now
        msg = "It is currently impossible to get data from the site"
        Hamster.report to: 'URYM6LD9V', message: msg
        MidlandCountyCovidCasesRuns.all.to_a.last.update(status: 'finished', data_checked: 'site is\'t responding')
        exit
      end
      retry
    end
    request.body
  end

  def full_get_page(host, link)
    begin
      request = Hamster.connect_to(
        url: link,
        headers: {
          'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
          'Sec-Fetch-Mode' => 'navigate',
          'Host' => host,
          'X-Client-Data' => 'COuSywE=',
          'X-Chrome-Connected' => 'source=Chrome,id=106006968995622645953,mode=0,enable_account_consistency=false,supervised=false,consistency_enabled_by_default=false'
        },
        proxy_filter: @proxy_filter,
        method: :get
      )
      raise if request&.headers.nil?

    rescue StandardError => e
      puts "#{e} | #{e.backtrace}"
      sleep(rand(5..10))
      if (@script_start + 1000) < Time.now
        msg = "It is currently impossible to get data from the site"
        Hamster.report to: 'URYM6LD9V', message: msg
        MidlandCountyCovidCasesRuns.all.to_a.last.update(status: 'finished', data_checked: 'site is\'t responding')
        exit
      end
      retry
    end
    request.body
  end

  def get_report_link
    host = 'www.midlandtexas.gov'
    page = get_page(host, SOURCE_LINK)
    html = Nokogiri::HTML(page)
    @report_link = html.css('iframe')[1]['src'].split('&')[0].to_s.sub('?widget=true', '')
  end

  def get_source_page
    host = 'docs.google.com'
    get_report_link
    @id = @report_link.scan(/\d+$/)[0]
    @data_page = full_get_page(host, @report_link)
  end

  def parse_data
    @html = Nokogiri::HTML(@data_page)
    concept_indexes = [0, 16, 23, 48, 59]
    report_date = get_report_date
    total_cases, total_tests = get_total_info
    check_data(total_cases)
    report_id = fill_report_table(report_date, total_cases, total_tests)
    report_info = get_report_info
    concept_indexes.each_with_index do |key, id|
      concept =   report_info[key]
      if concept != 'Medical Visit'
        labels_data = report_info[key + 1, concept_indexes[id+1] - concept_indexes[id] - 1]
      else
        labels_data = report_info[key + 1, report_info.size - concept_indexes[id] - 1]
      end
      n = ((concept == 'Patient Status') ? 2 : 3)
      labels_data.each_slice(n) do |data|
        label_name = data[0]
        label_cases = data[1].gsub(',', '').to_i
        label_pct = data[2].sub('%', '').to_f if n == 3
        fill_info_table(report_id, concept, label_name, label_cases, label_pct)
      end
    end
    MidlandCountyCovidCasesRuns.all.to_a.last.update(status: 'finished', data_checked: 'valid')
  end

  def fill_report_table(report_date, total_cases, total_tests)
    h = {}
    h[:report_date] = report_date
    h[:total_cases] = total_cases
    h[:total_tests] = total_tests
    h[:report_link] = @report_link
    h[:last_scrape_date] = @last_scrape_date
    h[:next_scrape_date] = @next_scrape_date
    h[:run_id] = @run_id
    h[:touched_run_id] = @run_id
    md5 =  @md5.hexdigest "#{report_date}#{total_cases}#{total_tests}"
    h[:md5_hash] = md5

    hash = MidlandCountyCovidCases.flail { |key| [key, h[key]] }
    MidlandCountyCovidCases.store(hash)
    report_id = MidlandCountyCovidCases.maximum(:id)
    report_id
  end

  def fill_info_table(report_id, concept, label, cases, pct_of_total)
    h = {}
    h[:report_id] = report_id
    h[:concept] = concept
    h[:label] = label
    h[:cases] = cases
    h[:pct_of_total] = pct_of_total
    h[:run_id] = @run_id
    h[:touched_run_id] = @run_id
    h[:last_scrape_date] = @last_scrape_date
    h[:next_scrape_date] = @next_scrape_date
    md5 =  @md5.hexdigest "#{report_id}#{concept}#{label}#{cases}#{pct_of_total}"
    h[:md5_hash] = md5

    hash = MidlandCountyCovidCasesInfo.flail { |key| [key, h[key]] }
    MidlandCountyCovidCasesInfo.store(hash)
  end

  def check_data(total_cases)
    gender_cases = 0
    gender_ids = [18, 21]
    data_rows = get_report_info
    concept1 = data_rows[0]
    concept2 = data_rows[16]
    concept3 = data_rows[23]
    concept4 = data_rows[48]
    concept5 = data_rows[59]

    if (concept1 != 'Source of Exposure' || concept2 != 'Gender' || concept3 != 'Age Range' || concept4 != 'Patient Status' || concept5 != 'Medical Visit')
      msg = "#{Time.now} - Midland County Bi-Weekly COVID-19 Report: The structure of the pages has been changed!!!"
      Hamster.report to: 'URYM6LD9V', message: msg
      MidlandCountyCovidCasesRuns.all.to_a.last.update(status: 'finished', data_checked: 'brocken page')
      exit
    end

    gender_ids.each do |id|
      gender_cases += data_rows[id].gsub(',', '').to_i
    end

    if total_cases != gender_cases
      msg = "#{Time.now} - Midland County Bi-Weekly COVID-19 Report: Report total cases are wrong!!!"
      Hamster.report to: 'URYM6LD9V', message: msg
      MidlandCountyCovidCasesRuns.all.to_a.last.update(status: 'finished', data_checked: 'brocken data')
      exit
    end
  end

  def get_report_info
    data_rows = @html.css("tr > td").map{|i| i&.content&.strip}
    data_rows.delete('')
    data_rows.delete('Cases')
    data_rows.delete('Percent of Total')
    reper_index = data_rows.index('Source of Exposure')
    data_rows = data_rows[reper_index, data_rows.size - reper_index]
    data_rows
  end

  def get_report_date
    report_date = /COVID-19 NUMBERS THROUGH \d{1,2}\/\d{1,2}\/\d{4}/.match(@html.to_s)
    if !report_date.nil?
      report_date = report_date[0].gsub('COVID-19 NUMBERS THROUGH ', '')
    end
    report_date = Date&.strptime(report_date, '%m/%d/%Y').to_s if !report_date.nil?
    report_date
  end

  def get_total_info
    total_cases = @html.at("td.s8")&.content&.gsub(',', '').to_i
    total_tests = @html.at("td.s9")&.content&.gsub(',', '').to_i
    [total_cases, total_tests]
  end

  def assign_new_run
    h = {}
    h[:status] = 'processing'
    hash = MidlandCountyCovidCasesRuns.flail { |key| [key, h[key]] }
    MidlandCountyCovidCasesRuns.store(hash)
  end
end


