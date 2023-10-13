# frozen_string_literal: true
#require_relative '../../../lib/specials/scrape/ext_connect_to'

class Scraper < Hamster::Scraper


  def initialize
    @cobble = Dasher.new(:using=>:cobble, redirect:true)
    start
  end

  def start

  end

  def params_query(params)
    raise( "!Params only Hash!" ) if !params.is_a?(Hash)
    params.map {|key, value| "#{CGI::escape(key)}=#{CGI::escape(value)}" }.join("&")
  end

  def general_page

    url = 'https://kaneapplications.countyofkane.org/DETAINEESEARCH/roster_search.aspx'
    first_page = @cobble.get(url)
    req_method = Parser.parse_post_request(first_page)
    cobble_with_parameters = Dasher.new(:using=>:cobble, redirect:true, req_body: params_query(req_method)) #cookies:cobble.cookies
    cobble_with_parameters.post(url)

  end

  def person_page(url)
    @cobble.get(url)
  end

end
