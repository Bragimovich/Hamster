# frozen_string_literal: true

require 'cgi'

require_relative 'connector'

class Scraper < Hamster::Scraper
  def initialize
    super

    @connector   = Connector.new
    @captcha_client = Hamster::CaptchaAdapter.new(:two_captcha_com, timeout:200, polling:10)
  end

  def get_html_page(url)
    begin
      response = @connector.get(url)
      html = response[:body] || ''
      raise CaptchaRequiredError if html.match?(/<form\s[^>]*\s?action="\/captcha_resp"/)
      html
    rescue CaptchaRequiredError
      logger.info 'Captcha requested. Trying to solve...'
      if @captcha_client.balance < 1
        logger.info 'Low 2Captcha balance.'
        @connector.switch_proxy
        retry
      end

      retry_other_proxy = false
      retry_count       = 0
      tc_retry_count    = 0
      begin
        # Download captcha image
        raw_captcha_image = ''
        stream_cb = Proc.new do |chunk|
          raw_captcha_image += chunk
        end

        response = @connector.get(
          'https://www.ark.org/captcha.gif',
          rotate_proxy:    false,
          stream_callback: stream_cb
        )

        if response.nil? || response[:status] != 200
          logger.info 'Failed to get the captcha image.'
          retry_other_proxy = true
          raise StandardError
        end

        captcha  = @captcha_client.decode!(raw: raw_captcha_image)
        logger.info "Decoded captcha - #{captcha.text}"
        req_body = "captcha_resp_txt=#{CGI.escape(captcha.text)}"

        response =
          @connector.post(
            'https://www.ark.org/captcha_resp',
            req_body,
            extra_headers:   { 'Content-Type' => 'application/x-www-form-urlencoded' },
            follow_redirect: false,
            rotate_proxy:    false
          ) do |resp|
            resp.success? || (resp.status >= 300 && resp.status < 400)
          end
        if response.nil?
          logger.info 'Captcha response submission failed.'
          retry_other_proxy = true
          raise StandardError
        end
      rescue TwoCaptcha::Error => e
        logger.info '2Captcha error occured.'
        logger.info e.full_message

        tc_retry_count += 1
        retry if tc_retry_count <= 20
        retry_other_proxy = true
      rescue StandardError => e
        unless retry_other_proxy
          retry_count += 1
          if retry_count <= 3
            retry
          end
          retry_other_proxy = true
        end
      end

      @connector.switch_proxy if retry_other_proxy
      retry
    end
  end

  def download_csv_file(url, file_path)
    file = open(file_path, "wb")
    stream_cb = Proc.new { |chunk| file.write chunk }

    @connector.get(url, stream_callback: stream_cb)
  ensure
    file.close unless file.nil?
  end

  private

  class CaptchaRequiredError < StandardError; end
end
