# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def initialize
    super

    @connector = Connector.new
  end

  def get_html_page(url)
    logger.info "Getting URL - #{url}"
    @connector.get(url)[:body]
  end

  def download_pdf_file(url, file_path)
    begin
      file = open(file_path, "wb")
      stream_cb = Proc.new { |chunk| file.write chunk }

      response =
        @connector.get(
          url,
          public_page_url: 'https://dchr.dc.gov/public-employee-salary-information',
          rotate_proxy:    false,
          stream_callback: stream_cb
        )

      if response.nil? || response[:status] != 200
        logger.info "Error while downloading PDF file - #{url}"
        file.close

        raise TryOtherProxy
      end
    rescue TryOtherProxy
      @connector.switch_proxy
      retry
    ensure
      file.close unless file.nil?
    end
  end

  private

  class TryOtherProxy < StandardError; end
end
