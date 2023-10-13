# frozen_string_literal: true

require_relative '../../../lib/specials/scrape/ext_connect_to'


class ScrapeLake < Hamster::Scraper
  attr_accessor :date_from, :date_to, :callback_page_index
  include ExtConnectTo

  BASE_URL = "https://apps03.lakecountyil.gov/inmatesearch/"

  private

  def params_query(params)
    raise( "!Params only Hash!" ) if !params.is_a?(Hash)
    params.map {|key, value| "#{CGI::escape(key).squish}=#{CGI::escape(value).squish}" }.join("&")
  end

  public

  def initialize
    super
    @date_to = DateTime.now
    @date_from = DateTime.now - 7
    @count_page = 1
    @current_page = 1
    @param_query_post_hash = {}
    init_var
  end

  def download
    download_index_start_page
    yield(@content_html) if block_given?

    while download_index_next_page
      yield(@content_html) if block_given?
    end

  end

  def download_index_start_page
    #https://apps03.lakecountyil.gov/inmatesearch/SearchResults.aspx?LastName=&FirstName=&BookingNumber=&FromDate=8/8/2022&ToDate=8/12/2022&Direct=N
    str_date_from = @date_from.strftime("%m/%d/%Y")
    str_date_to = @date_to.strftime("%m/%d/%Y")
    @param_query_hash = {
      "LastName"=>"",
      "FirstName"=>"",
      "BookingNumber"=>"",
      "FromDate"=>str_date_from,
      "ToDate"=>str_date_to,
      "Direct"=>"N"
    }
    tmp_param_query_post_hash = {}
    connect_to(url: "https://apps03.lakecountyil.gov/inmatesearch/SearchResults.aspx?#{params_query(@param_query_hash)}")
    tmp_param_query_post_hash, @count_page = @callback_page_index.call(content_html) unless @callback_page_index.nil?
    @param_query_post_hash.merge!(tmp_param_query_post_hash)
  end

  def download_index_next_page
    if @count_page > 1
      if @current_page < @count_page
        @current_page += 1
        @param_query_post_hash["__EVENTTARGET"]="SearchResultsGrid"
        @param_query_post_hash["__EVENTARGUMENT"]="Page$#{@current_page}"
        connect_to(url: "https://apps03.lakecountyil.gov/inmatesearch/SearchResults.aspx?#{params_query(@param_query_hash)}", req_body: params_query(@param_query_post_hash), method: :post)
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def download_content(indexs)
    indexs.each do |index|
      connect_to(url: index[:url])
      yield(index, @content_html) if block_given?
    end if indexs.size > 0
  end

  # Used only to go to the next "activities" page
  def next_page_content(content, func_callback)
    action, current_page, total_page, next_page, query_post_hash = func_callback.call(content)
    end_page = true
    end_page = false if next_page < total_page
    connect_to(url: BASE_URL + action, method: :post, req_body: params_query(query_post_hash) )
    [@content_html, end_page]
  end

  def download_photo(url)
    #https://apps03.lakecountyil.gov/inmatesearchmobile/GetPicture.aspx?BookingNumber=L172385
    connect_to(url:  url)
    [content_raw_html, Digest::MD5.hexdigest(url) + ".jfif"]
  end

end
