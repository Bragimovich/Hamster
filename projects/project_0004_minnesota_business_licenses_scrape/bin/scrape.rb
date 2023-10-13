# frozen_string_literal: true

require_relative '../lib/mn_biz_licenses_scraper'

LOGFILE = "mn_biz_licenses_scrape.log"

def scrape(options)
  log_dir  = "log/#{Hamster::PROJECT_DIR_NAME}_#{@project_number}/"
  log_path = "#{log_dir}#{LOGFILE}"
  
  FileUtils.mkdir_p(log_dir)
  File.open(log_path, 'a') { |file| file.puts Time.now.to_s }
  
  scraper = MNBizLicensesScraper.new
  
  if options[:download]
    scraper.download(options[:download])
  elsif options[:store]
    scraper.store_companies(options[:store])
  end
end
