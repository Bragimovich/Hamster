# frozen_string_literal: true

require 'cgi'

require_relative 'connector'

class Scraper < Hamster::Scraper
  def initialize
    super

    @site_conn =
      Connector.new(
        delay_connect:   0.2,
        public_page_url: 'http://www.ctinmateinfo.state.ct.us',
        try_non_proxy:   false
      )

    @api_conn =
      Connector.new(
        delay_connect: 0.2,
        extra_headers: { 'X-Vine-Application' => 'VINELINK' },
        try_non_proxy: false
      )
  end

  def get_site_content(url, options = {})
    get_content(@site_conn, url, options)
  end

  def get_api_content(url, options = {})
    content_type = options[:content_type] || :json
    get_content(@api_conn, url, options.merge({ content_type: content_type }))
  end

  def post_payload(url, payload)
    logger.info "Posting - #{url}"
    logger.info payload

    resp =
      @site_conn.post(
        url,
        params_encoded(payload),
        extra_headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      )

    resp[:body]
  end

  def reset_site_cookies
    @site_conn.reset_cookies
  end

  private

  def get_content(conn, url, options = {})
    options ||= {}
    content_type = options[:content_type] || :html
    bypass_codes = options[:bypass_codes] || []
    conn_options = options[:connector]
    conn_options = {} unless conn_options.is_a?(Hash)

    logger.info "Getting URL - #{url}"
    ct_header_regex =
      case content_type
      when :json
        /application\/json/
      when :image
        /image\//
      else
        /text\/html/
      end

    codes = bypass_codes.is_a?(Array) ? bypass_codes : []

    resp = conn.get(url, conn_options) do |response|
      (
        response.success? &&
        response.headers['content-type'].match?(ct_header_regex)
      ) ||
      codes.include?(response.status)
    end
    codes.include?(resp[:status]) ? nil : resp[:body]
  end

  def params_encoded(params)
    params.map{|key, val| "#{CGI.escape(key)}=#{CGI.escape(val || '')}"}.join('&')
  end
end
