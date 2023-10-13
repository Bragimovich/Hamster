# frozen_string_literal: true

require_relative '../lib/parser'
require_relative '../models/delaware_state_covid_data'
require_relative '../models/delaware_state_covid_data_run'

class Scraper < Hamster::Scraper
  
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  DATA_URL = "https://myhealthycommunity.dhss.delaware.gov/locations/state"
  VERIFICATION_URL = "https://myhealthycommunity.dhss.delaware.gov/about/acceptable-use?accept=on"
  REFERER = "https://myhealthycommunity.dhss.delaware.gov/about/acceptable-use"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @all_proxies = PaidProxy.all.to_a
    @parser = Parser.new
  end
 
  def set_deleted
    all_hashes = DelawareStateCovidData.where(:deleted => 0).distinct.pluck(:md5_hash)
    all_hashes.each do |md_hash|
      all_records = DelawareStateCovidData.where(:md5_hash => md_hash).order("id asc")
      next if all_records.count == 1
      all_records[0..-2].each do |record|
        DelawareStateCovidData.where(:id => record[:id]).update(:deleted => 1)
      end
    end
  end

  def download
    proxy = nil
    begin
      proxy = @all_proxies.shuffle.first
      raise "Bad proxy filtered" if @proxy_filter.filter(proxy).nil?
      response = connect_to(url:REFERER, proxy:proxy.to_s , ssl_verify:{:verify => true})
    rescue Exception => ex
      @proxy_filter.ban(proxy)
      retry
    end

    headers = prepare_headers(response, REFERER)
    verification_response = connect_to(url: VERIFICATION_URL, proxy_filter:nil, proxy:proxy.to_s,headers: headers, ssl_verify:{:verify => true})
    headers = prepare_headers(verification_response, REFERER)
    response = connect_to(url: DATA_URL, proxy_filter:nil, proxy:proxy.to_s,headers: headers, ssl_verify:{:verify => true})

    csv_url = @parser.fetch_csv_url(response)
    download_csv(csv_url, proxy, verification_response)
  end

  def parser
    Runs.insert({:date => Date.today})
    run_id = Runs.last_run

    data = @parser.parser(run_id[:id])
 
    data.each_slice(10000) do |records|
      DelawareStateCovidData.insert_all(records)
    end
    set_deleted
  end

  private

  def download_csv(csv_url, proxy, response)
    headers = prepare_headers(response, DATA_URL)
    response = connect_to(url: csv_url, proxy_filter:nil, proxy:proxy.to_s, headers:headers)    
    data_url = response.headers['location']    
    body = connect_to(url: data_url, proxy_filter:nil, proxy:proxy.to_s, headers: headers)&.body
    peon.put content:body, file: "#{Date.today}_data.csv"
  end

  def prepare_headers(response, referer)
    cookie = response.headers['set-cookie']
    headers = {
      Cookie:                    "#{cookie}",
      Referer:                   referer   
    }
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      reporting_request(response)
      break if response&.status && [200, 304,302].include?(response.status)
    end
    response
  end

  def reporting_request(response)
    puts '=================================='.yellow
    print 'Response status: '.indent(1, "\t").green
    status = "#{response.status}"
    puts response.status == 200 ? status.greenish : status.red
    puts '=================================='.yellow
  end
end
