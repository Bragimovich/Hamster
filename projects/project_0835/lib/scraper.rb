require 'nokogiri'
require 'uri'
require_relative 'parser'

class Scraper < Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def fetch_main_page
    url = "http://50.239.65.109/NewWorld.InmateInquiry/MI8218200"
    connect_to(url)
  end

  def search_request(name)
    url = "http://50.239.65.109/NewWorld.InmateInquiry/MI8218200?Name=#{name}&SubjectNumber=&BookingNumber=&BookingFromDate=&BookingToDate="
    connect_to(url: url, req_body: set_form_data(name),method: :post)
  end

  def current_page_html(url)
    connect_to(url)
  end
  
  def inmate_page(url)
    connect_to(url: url)
  end
  
  def inmate_page_html(url)
    base_url = "http://50.239.65.109"
    link = base_url + url
    connect_to(link)
  end

  def set_form_data(name)
    form_data = {
      'uxName' => name,
      'uxSubjectNumber' => '',
      'uxBookingNumber' => '',
      'uxBookingFromDate' => '',
      'uxBookingToDate' => '' 
    }
    form_data.map{|k| "#{k}"}.join("&")
  end

end