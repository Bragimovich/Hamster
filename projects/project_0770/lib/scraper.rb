# frozen_string_literal: true

require_relative 'connector'

class Scraper < Hamster::Scraper
  def initialize
    super

    @connector = Connector.new(delay_connect: 1, try_non_proxy: false)
  end

  def get_content(url, content_type = :html, bypass_500 = false)
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

    resp = @connector.get(url) do |response|
      (response.success? || (bypass_500 && response.status == 500)) &&
        response.headers['content-type'].match?(ct_header_regex)
    end
    resp[:status] == 500 ? nil : resp[:body]
  end
end
