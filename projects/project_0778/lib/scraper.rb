# frozen_string_literal: true

require 'cgi'

require_relative 'connector'

class Scraper < Hamster::Scraper
  def initialize
    super

    @connector = Connector.new(delay_connect: 2, try_non_proxy: false)
  end

  def get_content(url, content_type = :html, bypass_500 = false)
    logger.info "Getting page - #{url}"
    ct_header_regex =
      case content_type
      when :json
        /application\/json/
      when :image
        /image\//
      else
        /text\/html/
      end

    resp = @connector.get(url) do |response|
      (response.success? || (bypass_500 && response.status == 500)) &&
        response.headers['content-type'].match?(ct_header_regex)
    end
    resp[:status] == 500 ? nil : resp[:body]
  end

  def post_payload(url, payload)
    logger.info "Posting - #{url}"
    logger.info payload.select { |k, _| %w[__EVENTTARGET CollegeDDL AcadYearDDL DlCsvBtn].include?(k) }

    resp =
      @connector.post(
        url,
        params_encoded(payload),
        extra_headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        }
      )

    resp[:body]
  end

  def reset_connector_cookies
    @connector.reset_cookies
  end

  private

  def params_encoded(params)
    params.map{|key, val| "#{CGI.escape(key)}=#{CGI.escape(val || '')}"}.join('&')
  end
end
