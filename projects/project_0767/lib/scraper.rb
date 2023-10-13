# frozen_string_literal: true

require_relative 'connector'

class Scraper < Hamster::Scraper
  def initialize
    super

    @connector = Connector.new(delay_connect: 0.2, try_non_proxy: false)
  end

  def get_content(url, options = {})
    options ||= {}
    accept_type  = options[:accept_type] || :html
    bypass_codes = options[:bypass_codes] || []
    ret_response = !!options[:retrieve_response]
    conn_options = options[:connector]
    conn_options = {} unless conn_options.is_a?(Hash)

    logger.info "Getting URL - #{url}"
    ct_header_regex =
      case accept_type
      when :json
        /application\/json/
      when :image
        /image\//
      else
        /text\/html/
      end

    codes = bypass_codes.is_a?(Array) ? bypass_codes : []

    resp = @connector.get(url, conn_options) do |response|
      (
        response.success? &&
        response.headers['content-type'].match?(ct_header_regex)
      ) ||
      codes.include?(response.status)
    end
    codes.include?(resp[:status]) ? nil : (ret_response ? resp : resp[:body])
  end

  def post_payload(url, payload, options = {})
    options ||= {}
    content_type = options[:content_type] || 'application/x-www-form-urlencoded'

    logger.info "Posting - #{url}"
    logger.info payload

    payload = params_encoded(payload) if content_type == 'application/x-www-form-urlencoded'

    resp =
      @connector.post(
        url,
        payload,
        extra_headers: { 'Content-Type': content_type },
        multipart: content_type.include?('multipart/form-data')
      )

    resp[:body]
  end

  def reset_cookies
    @connector.reset_cookies
  end

  private

  def params_encoded(params)
    params.map{|key, val| "#{CGI.escape(key.to_s)}=#{CGI.escape(val&.to_s || '')}"}.join('&')
  end
end
