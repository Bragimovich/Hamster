require 'nokogiri'

class EndOfYearStudentDisciplineReportScraper < Hamster::Scraper
  HEADERS = {
    accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    accept_encoding:           'gzip, deflate',
    accept_language:           'en-US,en;q=0.9',
    cache_control:             'max-age=0',
    sec_fetch_dest:            'document',
    sec_fetch_mode:            'navigate',
    sec_fetch_site:            'none',
    sec_fetch_user:            '?1',
    upgrade_insecure_requests: '1',
    user_agent:                'Mozilla/5.0 (Windows NT 6.3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.66 Safari/537.36'
  }.freeze
  SOURCE_FILE = '-eoy-student-discipline.xlsx'

  def initialize
    super

    @file_path = "#{storehouse}store/"
    @trash_path = "#{storehouse}trash/"
    @webhost = 'https://www.isbe.net'
    FileUtils.mkdir_p storehouse + 'log/'
    @logger = Logger.new(storehouse + 'log/' + "scraping_#{Date.today.to_s}.log", 'monthly')
  end

  def scrape(academic_year=nil)
    peon.throw_trash(365)

    if academic_year.nil? && IlSchoolSuspension.maximum(:academic_year)
      recent_year = IlSchoolSuspension.maximum(:academic_year)
      academic_year = "#{recent_year[0..3].to_i + 1}-#{recent_year[-4..-1].to_i + 1}"
    end
    academic_year ||= '2017-2018'

    # report_me(to: 'sergii.butrymenko', message: "#{SCRAPE_NAME} Starting from academic year #{academic_year}", use: :both)

    @logger.info "Scraping everything from academic year: #{academic_year}."
    url = "https://www.isbe.net/Pages/Expulsions-Suspensions-and-Truants-by-District.aspx"
    # fa = FakeAgent.new
    # user_agent = fa.any

    response =
      Faraday.new(url: url, ssl: {verify: true}) do |c|
        c.headers = HEADERS #.merge({"User-Agent" => user_agent})
        c.adapter :net_http
        puts c.headers
      end.get

    if response.status == 200 && response.body.size.positive?
      puts 'STATUS 200. PROCEEDING'.green
    else
      puts "STATUS #{response.status}. ERROR".red
      return
    end

    content = Nokogiri::HTML(response.body).css('div#zone1').css('a')
    download_list = []
    content.each do |item|
      download_list << item['href'] if item.text[0..3].to_i >= academic_year[0..3].to_i
    end

    if download_list.empty?
      # recent_year = IlSchoolSuspension.maximum(:academic_year)
      # academic_year = "#{recent_year[0..3].to_i + 1}-#{recent_year[-4..-1].to_i + 1}"
      if content.first.text[0..3] == "#{academic_year[0..3].to_i - 1}"
        @logger.info "No new data found for academic year #{academic_year}."
        raise("No new data found for academic year #{academic_year}")
      else
        @logger.warn 'The web page structure were changed.'
        raise'The web page structure were changed.'
      end
    end

    download_list.each do |link|
      puts @webhost + link
      download_xlsx(@webhost + link)
    end
  end

  private

  def download_xlsx(url)
    puts 'Starting download'
    location = Net::HTTP.get_response(URI.parse(url))['location']
    file_name = location.split('/').last
    # puts "FILE NAME: #{file_name}"
    # puts "LINK TO LOCATION: #{location}"
    uri = URI(@webhost + location)
    # exit 1
    puts uri
    Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new uri
      http.request(request) do |response|
        while response.code == '301' || response.code == '302'
          # moved permanently or temporarily:  try again at the new location.
          response = http.get(URI.parse(response.header['location']))
          # ideally you should also bail if you make too many redirects.
        end
        file_status = check_response(response)
        puts file_status.cyan
        return file_status unless file_status.include?(SOURCE_FILE)
        File.open("#{@file_path}#{file_name}", 'w') do |file|
          response.read_body do |chunk|
            file.write(chunk)
          end
        end
        @logger.info("Downloading #{file_name} file.")
        # report_me("Downloading #{file_name} file.")
      end
    end
    # MainLogger.logger.info('Source file downloaded successfully.')
    # @logger.info('Source file downloaded successfully.')
    'downloaded'
  end

  def check_response(response)
    puts response.code.cyan
    case response.code.to_i
    when 200
      # MainLogger.logger.info("Return Code #{response.code}. Downloading updated xlsx file.")
      @logger.info("Return Code #{response.code}. Downloading xlsx file.")
      # report_me("Return Code #{response.code}. Downloading xlsx file.")
    when 404
      # MainLogger.logger.error("Return Code #{response.code}. Source xlsx file not found!")
      @logger.error("Return Code #{response.code}. Source xlsx file not found!")
      # report_me("Return Code #{response.code}. Source xlsx file not found!")
    when 400..499
      # MainLogger.logger.error("Return Code #{response.code}. Client error!")
      @logger.error("Return Code #{response.code}. Client error!")
      # report_me("Return Code #{response.code}. Client error!")
    when 500..599
      # MainLogger.logger.error("Return Code #{response.code}. Server error!")
      @logger.error("Return Code #{response.code}. Server error!")
      # report_me("Return Code #{response.code}. Server error!")
    else
      # MainLogger.logger.error("Return Code #{response.code}.")
      @logger.error("Return Code #{response.code}.")
      # report_me("Return Code #{response.code}.")
    end

    return 'response_error' unless response.code == '200'

    file_name = response.to_hash['content-disposition'].join.match(/(?<=filename=").*\.xlsx/)[0]
    if file_name.empty? || file_name[4..-1] != SOURCE_FILE
      # MainLogger.logger.warn("Source file name was changed from '#{SOURCE_FILE}' to '#{file_name}'.")
      @logger.warn('Source file name was changed.')
      # report_me('Source file name was changed.')
      return 'filename_changed'
    end
    file_name
  rescue StandardError => e
    @logger.error(e)
    raise
  end
end
