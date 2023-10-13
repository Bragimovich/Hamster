# frozen_string_literal: true

class Scraper <  Hamster::Scraper

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
  end

  def connect_to_main_page
    url =  "https://apps.isb.idaho.gov/licensing/attorney_roster.cfm"
    connect_to(url, req_body: get_form_data, proxy_filter: @proxy_filter, method: :post)
  end

  def connect_to_lawyer_info_page(link)
    connect_to(link)
  end

  private

  def get_form_data
    form_data = {
      "LastName" => "",
      "option" => "initial_page_load"
    }
    form_data.to_a.map { |val| val[0] + "=" + val[1] }.join("&")
  end

  def connect_to(*arguments, &block)
    response = nil
    10.times do
      response = super(*arguments, &block)
      break if response&.status && [200, 304 ,302].include?(response.status)
    end
    response
  end
end
