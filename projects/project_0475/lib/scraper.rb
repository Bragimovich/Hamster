# frozen_string_literal: true

require 'zip'

class Scraper < Hamster::Scraper
  def initialize(**options)
    safe_connection { super }
  end

  def good_proxies
    @proxy         = Camouflage.new
    # ----- create a list of good proxies for this URL -----
    @good_proxies = []
    proxies_count = @proxy.instance_variable_get("@proxies").size
    1.upto(proxies_count) do
      begin
        proxy = @proxy.swap
        @good_proxies << proxy if connect_to(url: WEBSITE_URL, proxy: proxy).status == 200
      rescue
        logger.debug("#{STARS}\nBad proxy: #{proxy}")
      end
    end
    pp @good_proxies
  end

  def clear
    name = Time.now.to_s.gsub(':', '-').split[0..1].join(' ')
    folder = "#{storehouse}store/"
    zipfile_name = "#{storehouse}trash/#{name}.zip"
    Zip::File.open(zipfile_name, create: true) do |zip|
      peon.list.each do |filename|
        zip.add(filename, File.join(folder, filename))
      end
    end
    FileUtils.rm Dir["#{folder}*"]
  end

  def store_to_csv(source, file_name)
    path = "#{storehouse}store/#{file_name}"
    CSV.open(path, 'a') do |csv|
      source.each do |record|
        csv << record.values
      end
    end
  end

  def get_source(url)
    safe_connection { connect_to(url: url) }
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
