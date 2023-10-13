# frozen_string_literal: true
require 'cgi'
require_relative 'connector'

class Scraper < Hamster::Scraper
  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @connector   = Connector.new
  end

  def get_request(url)
    retries = 0
    begin
      logger.info "Processing URL -> #{url}".yellow
      response = connect_to(url: url , proxy_filter: @proxy_filter)
      reporting_request(response)
      retries += 1
    end until response&.status == 200 or retries == 10
    [response , response&.status]
  end

  def download_csv_file(url, file_name)
    file_path = "#{storehouse}store/#{file_name}"
    file = open(file_path, "wb")
    stream_cb = Proc.new { |chunk| file.write chunk }

    @connector.get(url, stream_callback: stream_cb)
  ensure
    file.close unless file.nil?
  end

  private

  def reporting_request(response)
    if response.present?
      logger.info '=================================='.yellow
      logger.info 'Response status: '.indent(1, "\t").green
      status = "#{response.status}"
      logger.info response.status == 200 ? status.greenish : status.red
      logger.info '=================================='.yellow
    end
  end

end

