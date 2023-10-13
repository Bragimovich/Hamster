# frozen_string_literal: true

class Scraper < Hamster::Scraper
  def initialize(**options)
    safe_connection { super }
    @s3 = AwsS3.new(bucket_key = :us_court)
  end

  def save_to_aws(url_file, key_start)
    body = get_source(url_file)
    key = key_start + Time.now.to_i.to_s + '.pdf'
    @s3.put_file(body, key, metadata={url: url_file})
  end

  def get_source(url)
    safe_connection { connect_to(url: url)&.body }
  end

  def safe_connection(retries=10)
    begin
      yield if block_given?
    rescue *CONNECTION_ERROR_CLASSES => e
      begin
        retries -= 1
        raise 'Connection could not be established' if retries.zero?
        logger.warn("#{e.class}#{STARS}Reconnect!#{STARS}")
        sleep 100
        Hamster.report(to: OLEKSII_KUTS, message: "project-#{Hamster::project_number} Scraper: Reconnecting...")
        PaidProxy.connection.reconnect!
        UserAgent.connection.reconnect!
      rescue *CONNECTION_ERROR_CLASSES => e
        retry
      end
      retry
    end
  end
end
