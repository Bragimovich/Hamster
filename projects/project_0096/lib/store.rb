# frozen_string_literal: true

require_relative '../models/va_office_reports'
require 'aws-sdk-s3'

class Store <  Hamster::Scraper

  def initialize
    super  
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    s3 = get_aws_s3_client
    @bucket = s3.bucket('va-office-inspector-general')
  end

  def get_aws_s3_client
    aws_keys = Storage.new.aws_credentials
    Aws.config.update(
      access_key_id: (aws_keys['access_key_id']).to_s,
      secret_access_key: (aws_keys['secret_access_key']).to_s,
      region: 'us-east-1'
    )
    Aws::S3::Resource.new(region: 'us-east-1')
  end

  def connect_to(url , data_source_url)
    headers = { "Referer" => "#{data_source_url}" }
    retries = 0
    begin
      puts "Processing URL -> #{url}".yellow
      response = Hamster.connect_to(url: url, headers: headers, proxy_filter: @proxy_filter)
      reporting_request(response) 
      retries += 1
    end until response&.status == 200 or response&.status == 404 or response&.status == 301 or retries == 500
    response 
  end

  def download
    files_links = VaReports.where(:created_at => Date.today..DateTime::Infinity.new).pluck(:link_to_report , :data_source_url)
    return if files_links.empty?
    files_links.each do |link|
      next if link[0] == ""
      @file_name = link[0].split("/").last.gsub(".pdf" , "").strip
      source = connect_to(link[0] , link[1])
      next if source.status == 301
      next if source.status != 200
      result = source&.body
      save_pdf(result)
      upload_file(link[0])
    end
  end

  def upload_file(link)
    url = @bucket.put_object(
      :bucket => 'va-office-inspector-general',
      :key    => @file_name,
      :body   => IO.read("#{storehouse}store/#{@file_name}.pdf"),
      :tagging => "public=yes"
    ).public_url
    VaReports.where(:link_to_report => link).first.update(:link_to_report => url) 
  end

  def save_pdf(pdf)
    pdf_storage_path = "#{storehouse}store/#{@file_name}.pdf"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(pdf)
    end
  end

  def reporting_request(response)
    # unless @silence
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
    # end
  end
end
