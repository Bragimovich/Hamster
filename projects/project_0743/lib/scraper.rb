# frozen_string_literal: true
require_relative 'connector'
class Scraper < Hamster::Scraper
  def initialize
    super
    @connector = OhSchoolConnector.new('https://reportcard.education.ohio.gov/download')
  end

  def download(options)
    logger.debug("DOWNLOADING...")
    download_type_list = %w[Enrollment Assessment Graduation Gifted Attendance Teachers Expenditures]
    download_type_list = options[:type].split(',') if options[:type]
    response = @connector.do_connect('https://edu-prd-reportcard-datarefresh-api.azurewebsites.net/api/v2/CategoriesFileTypes/2022/25,26,27,29,30/0')
    file_list = JSON.parse(response.body)
    download_type_list.each do |download_type|
      folder_path = store_file_path(download_type)
      logger.debug("DOWNLOAD TYPE: #{download_type}, FOLDER_PTH: #{folder_path}")
      case download_type
      when 'Enrollment'
        files = file_list.select{|h| h['fileLocation'].match(/Enrollment_Building|Enrollment_District/i)}
        store_files(folder_path, files)
      when 'Assessment'
        files = file_list.select{|h| h['fileLocation'].match(/Achievement_Building|Achievement_District/i)}
        store_files(folder_path, files)
      when 'Graduation'
        files = file_list.select{|h| h['title'].match(/Federal Graduation Rate/i)}
        store_files(folder_path, files)
      when 'Gifted'
        files = file_list.select{|h| h['title'].match(/Gifted Indicator|Gifted District/i)}
        store_files(folder_path, files)
      when 'Attendance'
        files = file_list.select{|h| h['fileLocation'].match(/Title_1.xlsx/i)}
        store_files(folder_path, files)
      when 'Teachers'
        files = file_list.select{|h| h['title'].match(/Teacher/i)}
        store_files(folder_path, files)
      when 'Expenditures'
        files = file_list.select{|h| h['title'].match(/Expenditure Rankings/i)}
        store_files(folder_path, files)
      end
    end
  end

  def store_files(folder_path, files)
    files.each do |file|
      file_extension = file['fileLocation'].match(/.(x.+)/)[1]
      file_name = "#{file['title']}.#{file_extension}"
      file_location = file['fileLocation']
      file_path = "#{folder_path}/#{file_name}"

      logger.debug("DOWNLOADING FILE...: #{file_path}, LOCATION: #{file_location}")

      file_location = get_file_location(file_location)
      response = @connector.do_connect(file_location)
      store_data(file_path, response.body)
    end
  end

  def store_data(file_path, data)
    logger.debug("Downloading to -> #{file_path}")
    File.open(file_path, 'w+') do |f|
      f.puts(data)
    end
  end

  def store_file_path(download_type)
    store_path = "#{storehouse}store/#{Date.today.year}/#{download_type}"
    FileUtils.mkdir_p(store_path)
    store_path
  end

  def get_file_location(location)
    query_params={
      sv: '2020-08-04',
      ss: 'b',
      srt: 'sco',
      sp: 'rlx',
      se: '2031-07-28T05:10:18Z',
      st: '2021-07-27T21:10:18Z',
      spr: 'https',
      sig: 'nPOvW%2Br2caitHi%2F8WhYwU7xqalHo0dFrudeJq%2B%2Bmyuo%3D'
    }
    "#{location}?#{query_params.map{|q, v| "#{q}=#{v}"}.join('&')}"
  end
end
