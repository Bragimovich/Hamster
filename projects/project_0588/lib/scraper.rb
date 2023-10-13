require_relative '../../../lib/specials/aws_s3.rb'

class Scraper <  Hamster::Scraper
  BASE_URL = "https://www.njcourts.gov"
  STORE_FOLDER = "#{ENV['HOME']}/HarvestStorehouse/project_0588"

  def initialize
    super
    @proxy = Camouflage.new()
    @current_proxy = @proxy.swap
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 3000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_request(resource, access_token=nil)
    puts "Processing URL (GET REQUEST) -> #{BASE_URL}#{resource}".yellow
    url = BASE_URL + resource
    response = Hamster.connect_to(url: url, proxy_filter: @proxy_filter)
    reporting_request(response)
    response
  end

  def upload_file_aws(file_path, case_id)
    aws = AwsS3.new
    court_id = 331
    pdf_url = file_path
    file_name = pdf_url.split('/').last
    content = IO.read(file_path)
    key = 'us_courts_expansion/' + court_id.to_s + '/' + case_id.to_s + '/' + file_name
    aws_file_link = aws.put_file(content, key, metadata={})
    clean_dir(file_path)
    aws_file_link
  end

  def download_pdf(pdf_link)
    @url = BASE_URL + pdf_link
    file_name = pdf_link.split('/').last
    file_folder = STORE_FOLDER
    file_local_path = "#{file_folder}/#{file_name}"
    response = Hamster.connect_to(url: @url, proxy_filter: @proxy_filter)
    status = response.status if response.present?
    return if status != 200
    data = response.body
    File.write("#{file_local_path}", data)
    file_local_path
  end

  def clean_dir(path)
    FileUtils.rm_rf(path, secure: true)
  end

  def reporting_request(response)
    if response.present?
      puts '=================================='.yellow
      print 'Response status: '.indent(1, "\t").green
      status = "#{response.status}"
      puts response.status == 200 ? status.greenish : status.red
      puts '=================================='.yellow
    end
  end
end
