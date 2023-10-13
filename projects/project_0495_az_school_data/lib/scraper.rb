# frozen_string_literal: true

HEADERS = {
  accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  accept_language:           'en-US,en;q=0.5',
  connection:                'keep-alive',
  upgrade_insecure_requests: '1'
}

require 'zip'

class Scraper < Hamster::Scraper
  
  # sub_dir: ex: "assessment/"
  def download_xlsx_file(url, filename, sub_dir = '')
    dirname = storehouse+"store/#{sub_dir}"
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
    flag = false
    until flag do 
      flag = true
      begin
        Hamster.logger.info "Connecting #{url}"
        connect_to(url: url, method: :get_file, filename: dirname + filename, headers: HEADERS)
        Hamster.logger.info "unzip #{dirname + filename}"
        unzip(dirname + filename)
      rescue 
        Hamster.logger.info "Rescue again"
        flag = false
      end
    end
  end

  def get_assessment_xlsx_files
    Dir["#{storehouse}store/assessment/*.xlsx"]
  end

  def get_enrollment_xlsx_files
    Dir["#{storehouse}store/enrollment/*.xlsx"]
  end

  def get_dropout_xlsx_files
    Dir["#{storehouse}store/dropout/*.xlsx"]
  end

  def get_cohort_xlsx_files
    Dir["#{storehouse}store/cohort/*.xlsx"]
  end

  def clear_assessment_files
    File.delete(*Dir.glob("#{storehouse}store/assessment/*"))
  end

  def clear_enrollment_files
    File.delete(*Dir.glob("#{storehouse}store/enrollment/*"))
  end

  def clear_dropout_files
    File.delete(*Dir.glob("#{storehouse}store/dropout/*"))
  end

  def clear_cohort_files
    File.delete(*Dir.glob("#{storehouse}store/cohort/*"))
  end

  def unzip(file_path)
    trash_path = storehouse + 'trash/'    
    Zip::File.open(file_path) do |zip_file|
      zip_file.each do |f|
        if (!f.name.downcase.include?('fileheader') && !f.name.include?('.xlsx'))
          zip_file.extract(f, file_path) unless File.exist?(file_path)
        end
      end
    end
    # FileUtils.mkdir_p trash_path
    # FileUtils.mv(file_path, trash_path + 'temp.zip')
  end

  def get_response(url)
    connect_to(url)
  end

end