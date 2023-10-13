# frozen_string_literal: true

class Scraper < Hamster::Scraper
  attr_accessor :s3

  def initialize
    super
    @s3 = AwsS3.new(bucket_key = :us_court)
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc {|response| [200, 304].include?(response.status) || response.body.size.zero?}
  end

  def get_source(url)
    connect_to(url: url, proxy_filter: @filter, ssl_verify: false)
  end

  def get_pdf(url, casename)
    filename = url.split('/').last
    dirname = "#{storehouse}store/#{casename}/"
    file_name = dirname + filename

    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    begin
      response = connect_to(url, method: :get_file, filename: file_name, ssl_verify: false)
      pdf = PDF::Reader.new(file_name)
      rescue PDF::Reader::MalformedPDFError
    end
    pdf
  end

  def get_source_case_opinion(url, page=1)
    response = connect_to(url: url + page.to_s, proxy_filter: @filter, ssl_verify: false)
  end

  def save_to_aws(url_file, key_start)
    response = connect_to(url_file, ssl_verify: false)
    key = key_start + Time.now.to_i.to_s + '.pdf'
    aws_link = s3.put_file(response.body, key, metadata={url: url_file})
    aws_link
  end
end
