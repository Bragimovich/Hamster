# frozen_string_literal: true

require_relative '../models/FSCALPdfs'
require_relative '../models/FSCALNames'
require 'aws-sdk-s3'

class Store <  Hamster::Scraper

  def initialize
    super  
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @pdf_urls = FSCALPdfs.pluck(:pdf_link_on_aws , :case_no)
    bucketname = Storage.new.buckets[:us_court]
    s3 = get_aws_s3_client
    @bucket = s3.bucket(bucketname)
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

  def store
    @pdf_urls.each do |data|
      pdf_url = data.first
      case_no = data.last 
      next if pdf_url.include? "court-cases-activities.s3.amazonaws.com"
      file_name = pdf_url.split("/").last.gsub(".pdf" , "_#{case_no.split.join("_")}")
      upload_file(file_name , pdf_url)  
    end
  end

  def upload_file(file_name , pdf_url)  
    body = IO.read("#{storehouse}store/#{file_name}.pdf")
    key = "florida_supreme_court_#{file_name}.pdf"
    url = @bucket.put_object(
      acl: 'public-read',
      key: key,
      body: body,
      metadata: {}
    ).public_url
    begin
    FSCALPdfs.where(:pdf_link_on_aws => pdf_url).first.update(:pdf_link_on_aws => url)
    rescue Exception => e
     return
    end
  end
end

