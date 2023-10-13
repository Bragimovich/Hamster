# frozen_string_literal: true
require_relative '../lib/parser'

class Scraper < Hamster::Scraper

  attr_reader :data_source_url
  def initialize
    super
    @data_source_url = "https://data.vermont.gov/api/views/jgqy-2smf/rows.csv?accessType=DOWNLOAD"
  end

  def download_csv
    response = nil
    
    10.times do
      response = Hamster.connect_to(@data_source_url)
      reporting_request response
      
      break if [200,301,304,308,307].include?(response&.status)
    end
    
    unless response&.headers["content-disposition"].nil?
      logger.debug 'successfully downloaded file'
      response&.body 
    end
  end

  def safe_connection(retries=10) 
    begin
      yield if block_given?
    rescue *connection_error_classes => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        logger.error(e)
        sleep 100
        PaidProxy.connection.reconnect!
        UserAgent.connection.reconnect!
      rescue *connection_error_classes => e
        retry
      end

      retry
    end
  end

  private

  def reporting_request(response)
    logger.debug '=================================='
    logger.debug 'Response status: '.indent(1, "\t")
    status = response&.status
    logger.debug status.to_s
    logger.debug '=================================='
  end
  
  def connection_error_classes
    [
      ActiveRecord::ConnectionNotEstablished,
      Mysql2::Error::ConnectionError,
      ActiveRecord::StatementInvalid,
      ActiveRecord::LockWaitTimeout
    ]
  end
end
