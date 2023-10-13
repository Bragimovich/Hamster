require_relative 'connector'
require_relative 'parser'
require 'zip'

class Scraper < Hamster::Scraper
  def initialize
    super
    @parser = Parser.new
    @connector = WiReportCardConnector.new('https://apps2.dpi.wi.gov/reportcards/home')
  end

  def get(url)
    @connector.do_connect(url)
  end

  def scrape_zip_files(type_list)
    zip_file_page_urls.each do |url|
      download_type = url.match(/value=(\w+)$/)[1]
      next if type_list && type_list.exclude?(download_type)
      download_zip_files(url)
    end
  end

  def download_zip_files(url)
    download_type = url.match(/value=(\w+)$/)[1]
    response = get(url)
    zip_links = @parser.zip_file_links(response.body, download_type)
    zip_links.each do |zip_link|
      file_path = "#{store_file_path(download_type)}/#{zip_link[:name]}"
      response = get(zip_link[:url])
      store_data(file_path, response.body)
      extract_zip_file(file_path, download_type)
      File.delete(file_path) if File.exist?(file_path)
    end
  end

  def store_data(file_path, data)
    logger.debug("Downloading to -> #{file_path}")
    File.open(file_path, 'w+') do |f|
      f.puts(data)
    end
  end

  def extract_zip_file(zip_file_path, download_type)
    destination_folder = store_file_path(download_type)
    Zip::File.open(zip_file_path) do |zip_file|
      zip_file.each do |entry|
        next if entry.name.match(/DataDisclaimer|_layout/)
        destination_file = File.join(destination_folder, entry.name)
        entry.extract(destination_file)
      end
    end
  rescue => e
    logger.info e.full_message
  end

  def store_file_path(download_type)
    store_path = "#{storehouse}store/#{Date.today.year}/#{download_type}"
    FileUtils.mkdir_p(store_path)
    store_path
  end

  def zip_file_page_urls
    [
      "https://dpi.wi.gov/wisedash/download-files/type?field_wisedash_upload_type_value=Enrollment",
      "https://dpi.wi.gov/wisedash/download-files/type?field_wisedash_upload_type_value=WSAS",
      "https://dpi.wi.gov/wisedash/download-files/type?field_wisedash_upload_type_value=ACT11",
      "https://dpi.wi.gov/wisedash/download-files/type?field_wisedash_upload_type_value=ACT",
      "https://dpi.wi.gov/wisedash/download-files/type?field_wisedash_upload_type_value=Aspire",
      "https://dpi.wi.gov/wisedash/download-files/type?field_wisedash_upload_type_value=Forward",
      "https://dpi.wi.gov/wisedash/download-files/type?field_wisedash_upload_type_value=Discipline",
      "https://dpi.wi.gov/wisedash/download-files/type?field_wisedash_upload_type_value=Attendance"
    ]
  end
end
