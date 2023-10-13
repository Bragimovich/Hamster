# frozen_string_literal: true

require_relative 'connector'

class Scraper < Hamster::Scraper
  def initialize
    super

    @connector = Connector.new(delay_connect: 0.2, try_non_proxy: false)
  end

  def get_content(url, content_type = :html, bypass_codes = nil)
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

    resp = @connector.get(url) do |response|
      (
        response.success? &&
        response.headers['content-type'].match?(ct_header_regex)
      ) ||
      codes.include?(response.status)
    end
    codes.include?(resp[:status]) ? nil : resp[:body]
  end

  def post_payload(url, payload, bypass_codes = nil)
    logger.info "Posting - #{url}"
    logger.info payload

    codes = bypass_codes.is_a?(Array) ? bypass_codes : []

    resp =
      @connector.post(url, payload, extra_headers: { 'Content-Type': 'application/json' }) do |response|
        response.success? || codes.include?(response.status)
      end

    codes.include?(resp[:status]) ? nil : resp[:body]
  end
end
