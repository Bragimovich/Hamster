# frozen_string_literal: true

require_relative 'connector'
require_relative 'parser'
class Scraper < Hamster::Scraper
  def initialize
    super
    @connector = NcConnector.new('https://www.dpi.nc.gov')
    @parser = Parser.new
  end

  def scrape_xls_files(key, links)
    links.each do |link|
      response = @connector.do_connect(link)
      xls_file_links = @parser.xls_file_links(key, response.body)
      xls_file_links.each do |links|
        begin
          next unless links

          name = links[:name]
          xls_link = links[:url]
          xls_link = "https://www.dpi.nc.gov#{xls_link}" unless xls_link.match(/dpi.nc.gov/)
          logger.debug "Downloading xls file link: #{xls_link}"
          response = @connector.do_connect(xls_link)

          raise XlsFileRequiredError if response.body.match(/DOCTYPE html/)

          if name.match(/xls/) && !name.match(/xlsx/)
            file_path = "#{store_file_path(key)}/#{name}.xls"
          else
            file_path = "#{store_file_path(key)}/#{name}.xlsx"
          end
          store_data(file_path, response.body) if response.headers['content-type'].match(/zip|spreadsheetml|cdfv2/)
        rescue XlsFileRequiredError => e
          links = @parser.xls_file_links(:assessment, response.body).first

          logger.debug "Retrying #{links}"
          retry
        end
      end
    end
  end

  def store_file_path(key)
    store_path = "#{storehouse}store/#{Date.today.year}/#{key}"
    FileUtils.mkdir_p(store_path)
    store_path
  end

  private

  def store_data(file_path, data)
    logger.debug "Store xls file file_path: #{file_path}"
    File.open(file_path, 'w+') do |f|
      f.puts(data)
    end
  end
  class XlsFileRequiredError < StandardError; end
end
