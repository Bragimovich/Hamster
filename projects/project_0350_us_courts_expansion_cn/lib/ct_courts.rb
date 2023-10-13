# frozen_string_literal: true

require_relative './database_manager'

class CTCourtsScrape < Hamster::Scraper

  DIR_MAIN = '../HarvestStorehouse/project_0350/'
  START_LETTERS = 'AA'
  LAST_LETTERS = 'ZZ'
  THREADS_COUNT_SCRAPING = 10

  DIR_MAIN_SCRAPE = '../HarvestStorehouse/project_0350/main_scrape_'
  DIR_MAIN_RESULT = '../HarvestStorehouse/project_0350/main_results_'
  DIR_TEST = '../HarvestStorehouse/project_0350/test'

  RANGE = "#{START_LETTERS}_-_#{LAST_LETTERS}"

  def connect_to(*arguments, &block)
    response = nil

    begin
      3.times do
        response = super(*arguments, &block)
        break if response&.status && [200, 304].include?(response.status)
      end
    rescue ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout => e
      sleep 120
      retry
    end

    response
  end

  def get_form_data
    form_data = {
      '__EVENTTARGET' => 'lnkbPrinterFriendly',
      '__EVENTARGUMENT' => '',
      '__VIEWSTATE' => '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',
      '__VIEWSTATEGENERATOR' => '6CEFA833',
      '__EVENTVALIDATION' => '/wEdAAlsYu3cXCLf8LeOOwOUAcTkfyfHVAgchqN4Fmknd/UrlbZ4WkbHQhRjOC9n5rt429E5kwl0mGQmfQyJyNS3Ej5R60nAjIobJkQI3xQW2aidAgnjwWFQEKNaCIxReqAmCSemBzac80FHJtezn884BfTqYosL01GCUdj5Es2roypOdQ1Xf16nxs+HFRvSAg1DTyaWUOKq6LaXXPdhB9wrGdzcgcLXJw=='
    }
    URI.encode_www_form(form_data)
  end

  def initialize
    @default_link = 'http://appellateinquiry.jud.ct.gov/CaseDetail.aspx?'
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
    @scraping_date = Time.now
    @scrape_dev_name = 'Dmitry Suschinsky'
    @semaphore = Mutex.new
    @run_id = nil
    @form_data = get_form_data

    @ct_document_list = CTDocumentList
    @ct_case_detail = CTCaseDetail
  end

  def get_count_records(page)
    document = Nokogiri::HTML(page)
    count_records = 0
    document.xpath('//a[starts-with(@id, "gridResultsParty_ct")]').each { |x| count_records += 1 }

    count_records
  end

  # download main pages
  def main_first_part(start_date, type, end_date)
    search_value = 'nil'
    case type
    when 'Supreme'
      _type = 'SC'
    when 'Appellate'
      _type = 'AC'
    end

    start_date = start_date.strftime("%Y-%m-%d") if start_date.class != String

    array = []
    range = []

    # SCRAPE PART #1
    1.times do |i|
      array += (START_LETTERS..LAST_LETTERS).collect { |e| e * (i + 1) }
      range += (START_LETTERS..LAST_LETTERS).collect { |e| e * (i + 1) }
    end

    array.reverse!

    dirname = create_dir(DIR_MAIN_SCRAPE + "#{type}_" + start_date)

    threads = Array.new(THREADS_COUNT_SCRAPING) do
      Thread.new do
        loop do
          search_value = nil
          @semaphore.synchronize do
            search_value = array.pop
          end
          break if search_value.nil?

          url = "https://appellateinquiry.jud.ct.gov/SearchResults.aspx?CallingPage=PartyName&PN=#{search_value}&C=#{_type}&CS=All&SD=#{start_date}&ED=#{end_date}"

          save_index_pages(url, dirname, search_value)
        end
      end
    end
    threads.each(&:join)
    Hamster.report(to: 'Dmitiry Suschinsky', message: '#350 Connecticut Courts - MAIN PART #1 - DONE')
  rescue SystemExit, Interrupt, StandardError => e
    error_msg = e.backtrace.join("\n")
    Hamster.report(to: 'dmitiry.suschinsky',
                   message: "#350 Connecticut Courts MAIN PART #1 - exception:\n #{error_msg}\n SEARCH_VALUE: #{search_value}")
  end

  # download personal pages
  def main_second_part(start_date, type)
    # SCRAPE PART #2
    count = 0
    start_date = start_date.strftime("%Y-%m-%d") if start_date.class != String

    dirname = create_dir(DIR_MAIN_RESULT + "#{type}_" + start_date)
    filelist = Array.new
    Dir["#{DIR_MAIN_SCRAPE + "#{type}_" + start_date}/*.gz"].each do |path|
      next if path.to_s.include?('DONE')
      filelist.push(path)
    end
    total_count = filelist.size
    total_count_records = 0

    filelist.each do |path|
      index = 0
      count += 1
      total_count -= 1

      file = read_gz(path)
      filename = path.scan(/#{Regexp.escape(DIR_MAIN_SCRAPE + "#{type}_" + start_date)}\/(\S+\.gz)$/)

      search_value = path.scan(/\/(\w+)_count_\d+.gz$/)[0][0]

      document = Nokogiri::HTML.parse(file)
      links = document.css('a[href]').select { |e| e['id'] =~ /gridResultsParty_ct/ }
      count_records = links.size
      total_count_records += count_records

      threads_links = Array.new(15) do
        Thread.new do
          loop do
            break if links.size == 0

            link = nil

            @semaphore.synchronize do
              link = links.pop
              index += 1
            end
            break if link.nil?

            url = "http://appellateinquiry.jud.ct.gov/#{link['href']}"
            save_page(url, dirname, search_value, link['href'], index)
          end
        end
      end
      threads_links.each(&:join)

      File.rename(path, path.gsub(filename[0][0].to_s, "DONE_#{filename[0][0].to_s}")) if File.exist?(path)
    end
    Hamster.report(to: 'Dmitiry Suschinsky', message: '#350 Connecticut Courts - MAIN PART #2 - DONE')
  rescue SystemExit, Interrupt, StandardError => e
    error_msg = e.backtrace.join("\n")
    Hamster.report(to: 'dmitiry.suschinsky',
                   message: "#350 Connecticut Courts MAIN PART #2 - exception:\n #{error_msg}")
  end

  # parse each page
  def parse_part(start_date, type)
    # PARSE PART
    count = 0
    mark_as_started
    start_date = start_date.strftime("%Y-%m-%d") if start_date.class != String

    case type
    when 'Supreme'
      court_id = 307
      _type = 'SC'
    when 'Appellate'
      court_id = 414
      _type = 'AC'
    end

    filelist = Array.new
    Dir["#{DIR_MAIN_RESULT + "#{type}_" + start_date}/*.gz"].each do |path|
      next if path.to_s.include?('DONE')
      filelist.push(path)
    end
    total_count = filelist.size
    total_count_records = filelist.size
    filelist.reverse!

    threads_links = Array.new(2) do
      Thread.new do
        loop do
          break if filelist.size == 0

          path = nil

          @semaphore.synchronize do
            path = filelist.pop
          end
          break if path.nil?

          count += 1
          total_count -= 1

          file = read_gz(path)
          next if file.nil?

          filename = path.scan(/#{Regexp.escape(DIR_MAIN_RESULT + "#{type}_" + start_date)}\/(\S+\.gz)$/)
          result = path.scan(/(\w+)_(\d+)_link_(\S+).gz$/)
          link = result[0][2]

          case_detail = @ct_case_detail.new(file, @default_link + link, @scraping_date, @scrape_dev_name, court_id,
                                            @run_id)
          document_list = @ct_document_list.new(file, @default_link + link, @scraping_date, @scrape_dev_name, court_id,
                                                @run_id)

          ct_put_all_in_db_sql(case_detail, document_list)

          File.rename(path, path.gsub(filename[0][0].to_s, "DONE_#{filename[0][0].to_s}")) if File.exist?(path)
        end
      end
    end
    threads_links.each(&:join)

    Hamster.report(to: 'dmitiry.suschinsky',
                   message: "#350 Connecticut Courts - PARSE PART - DONE (#{type}: #{total_count_records}/#{start_date})")

  rescue SystemExit, Interrupt, StandardError => e
    error_msg = e.backtrace.join("\n")
    Hamster.report(to: 'dmitiry.suschinsky', message: "#350 Connecticut Courts - exception:\n #{error_msg}")
  end

  def rename_files(type, start_date)
    filelist = Array.new
    Dir["#{DIR_MAIN_RESULT + "#{type}_" + (start_date.gsub('/', '_'))}/*.gz"].each do |path|
      filelist.push(path)
    end

    filelist.each do |path|
      File.rename(path, path.gsub('DONE_', '')) if File.exist?(path)
    end
  end

  def update(types, start_d, end_d)
    types.each do |type|
      if start_d.blank? && end_d.blank?
        date = get_last_week_dates
      else
        date = { start_week: start_d, end_week: end_d }
      end

      sleep 10
      main_first_part(date[:start_week], type, date[:end_week])

      sleep 30
      main_second_part(date[:start_week], type)

      sleep 30
      parse_part(date[:start_week], type)
    end
  end

  def save_index_pages(page_link, dirname, search_value)
    page = connect_to(url: page_link, method: :post, req_body: @form_data, proxy_filter: @filter, ssl_verify: false)&.body
    count_records = get_count_records(page)
    # https://appellateinquiry.jud.ct.gov/SearchResults.aspx?CallingPage=PartyName&PN=AB&C=AC&CS=All&SD=2023-01-16&ED=2023-01-22
    pack_to_gz(dirname, search_value + "_count_#{count_records}", page) if page != nil && count_records > 0
  end

  def save_page(page_link, dirname, search_value, href, index)
    response = connect_to(url: page_link, method: :post, req_body: @form_data, proxy_filter: @filter, ssl_verify: false)

    pack_to_gz(dirname, search_value + "_#{index}" + "_link_#{href.scan(/.aspx\?(\S+)$/)[0][0]}",
               response&.body) if response&.status == 200
  end

  def pack_to_gz(dir, name, html)
    Zlib::GzipWriter.open(gz_file(dir, name)) do |gz|
      gz.write(html)
    end
    File.rename(gz_file(dir, name), gz_file(dir, name))
  end

  def create_dir(dir)
    dirname = dir
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    "#{dirname}/"
  end

  def gz_file(dir, name)
    "#{dir}#{name.gsub(/\..+/, '')}.gz"
  end

  def read_gz(dir)
    Zlib::GzipReader.open(dir, &:read)
  end

  private

  def mark_as_started
    last_row = CtSaacCaseRuns.last
    if last_row && last_row.status == 'parse started'
      @run_id = last_row.id
    else
      CtSaacCaseRuns.create
      @run_id = CtSaacCaseRuns.last.id
      CtSaacCaseRuns.find(@run_id).update(status: 'parse started')
      CtSaacCaseRuns.find(@run_id - 1).update(status: 'done') if @run_id > 1
    end
  end

  def mark_as_done
    last_row = CtSaacCaseRuns.last
    if last_row && last_row.status == 'parse started'
      @run_id = last_row.id
      CtSaacCaseRuns.find(@run_id).update(status: 'done')
    end
  end

  def get_last_week_dates
    date = Date.today
    start_week = date - date.wday - 6
    end_week = date - date.wday

    { start_week: start_week, end_week: end_week }
  rescue SystemExit, Interrupt, StandardError => e
  end

end
