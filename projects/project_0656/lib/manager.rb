# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require 'zip'
require 'mdb'

class Manager < Hamster::Harvester

  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
  end

  def download
    grad_and_assess_response = scraper.connect_to('https://data.nysed.gov/downloads.php')
    download_grad_and_assesment_files(grad_and_assess_response.body)
    nyc_and_ros_response = scraper.connect_to('https://www.p12.nysed.gov/irs/school_safety/school_safety_data_reporting.html')
    download_nyc_and_ros_files(nyc_and_ros_response.body)
    salaries_response = scraper.connect_to('https://www.p12.nysed.gov/mgtserv/admincomp/')
    download_salaries_files(salaries_response.body)
    enroll_source_1_response = scraper.connect_to('https://www.p12.nysed.gov/irs/statistics/enroll-n-staff/home.html')
    download_enrolement_files(enroll_source_1_response.body)
    enroll_source_2_response = scraper.connect_to('https://www.p12.nysed.gov/irs/statistics/enroll-n-staff/ArchiveEnrollmentData.html')
    download_enrolement_files(enroll_source_2_response.body)
  end

  def store
    insert_general_info_data
    ids_and_numbers = keeper.pluck_ids_numbers
    ids_and_names = keeper.pluck_ids_names
    parser.initialize_values(ids_and_numbers, ids_and_names, keeper.run_id)
    store_expenditure_files
    store_absenteeism_files
    store_elp_files
    store_regent_files
    store_enrollment_files
    store_graduation_files
    store_assessment_files
    store_salaries_files
    store_safety_files
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def download_grad_and_assesment_files(response)
    domain = 'https://data.nysed.gov'
    grad_links,asses_links = parser.get_grad_and_assesment_files_links(response)
    download_inner_links(domain, grad_links, 'Graduation')
    download_inner_links(domain, asses_links, 'Assessment')
  end

  def download_nyc_and_ros_files(response)
    domain = 'https://www.p12.nysed.gov'
    nyc_and_ros_links = parser.get_nyc_and_ros_links(response)
    download_inner_links(domain, nyc_and_ros_links, 'NYC_and_ROS')
  end

  def download_salaries_files(response)
    domain = 'https://www.p12.nysed.gov/mgtserv/admincomp/'
    salaries_links = parser.get_salaries_links(response)
    download_inner_links(domain, salaries_links, 'Salaries')
  end

  def download_enrolement_files(response)
    domain = 'https://www.p12.nysed.gov/irs/statistics/enroll-n-staff/'
    enrollment_links = parser.get_enrollment_links(response)
    download_inner_links(domain, enrollment_links, 'Enrollment')
  end

  def download_inner_links(domain, links, type)
    downloaded_files = get_downloaded_files(type)
    links.each do |link|
      extension = link.split('.').last
      file_name = "#{link.scan(/[a-zA-Z0-9]+/).join('_').gsub("_#{extension}", '')}"
      url = (link.include? 'http') ? "#{link}" : "#{domain}#{link}"
      url = url.gsub('admincomp/../','') if (url.include? '../')
      next if downloaded_files.include? file_name
      inner_response = scraper.connect_to(url)
      save_file(inner_response.body, file_name, type, extension)
    end
  end

  def insert_general_info_data
    inserted_md5 = keeper.get_inserted_md5
    district_table_data = keeper.pluck_district_table_data('us_district')
    district_table_data = district_table_data.reject{ |e| inserted_md5.include? e[11] }
    keeper.insert_district_data(district_table_data,keeper.run_id)
    school_table_data = keeper.pluck_school_table_data('us_school')
    school_table_data = school_table_data.reject{ |e| inserted_md5.include? e[18] }
    keeper.insert_school_data(school_table_data,keeper.run_id)
  end

  def store_graduation_files
    extract_zip_files('Graduation')
    files = get_files('Graduation', '*.csv')
    files.each do |file|
      data_array = parser.parse_graduation_data(file)
      keeper.insert_records(data_array, 'ny_grad')
    end
  end

  def store_assessment_files
    files = get_files('Report', '*').select{ |e| ((e.include? 'annual_em') || (e.include? 'nysaa')) }
    files.each do |file|
      data_array = parser.parse_assesement_data(file)
      keeper.insert_records(data_array, 'ny_assess')
      file_handling(file, 'a', 'processed')
    end
  end

  def store_enrollment_files
    files = get_files('Enrollment', '*')
    files.each do |file|
      data_array = parser.parse_enrollment_data(file)
      keeper.insert_records(data_array, 'ny_enroll')
    end
  end

  def store_salaries_files
    files = get_files('Salaries', '*')
    files.each do |file|
      next if (file.include? 'docs_AdminComp6_11_07')
      data_array = parser.parse_salaries_data(file)
      keeper.insert_records(data_array, 'ny_salarie')
    end
  end

  def store_safety_files
    files = get_files('NYC_and_ROS', '*')
    files.each do |file|
      data_array = parser.parse_safety_data(file)
      keeper.insert_records(data_array, 'ny_safe')
    end
  end

  def store_expenditure_files
    files = get_files('Report', '*').select{ |e| e.include? 'expend' }
    files.each do |file|
      data_array = parser.parse_expenditure_data(file)
      keeper.insert_records(data_array, 'ny_exp')
    end
  end

  def store_absenteeism_files
    files = get_files('Report', '*').select{ |e| e.include? 'absent' }
    files.each do |file|
      data_array = parser.parse_absenteeism_data(file)
      keeper.insert_records(data_array, 'ny_absen')
    end
  end

  def store_elp_files
    files = get_files('Report', '*').select{ |e| e.include? 'elp' }
    files.each do |file|
      data_array = parser.parse_elp_data(file)
      keeper.insert_records(data_array, 'ny_elp')
    end
  end

  def store_regent_files
    files = get_files('Report', '*').select{ |e| e.include? 'regent' }
    files.each do |file|
      data_array = parser.parse_regent_data(file)
      keeper.insert_records(data_array, 'ny_reg')
    end
  end

  def get_files(folder, file_type)
    Dir["#{storehouse}store/#{keeper.run_id}/#{folder}/**/#{file_type}"]
  end

  def extract_zip_files(folder)
    zip_files_path = Dir["#{storehouse}store/#{keeper.run_id}/#{folder}/*"]
    zip_files_path.each do |file_path|
      begin
        Zip::File.open(file_path) do |zip_file|
          zip_file.each do |entry|
            output_path = File.join(File.dirname(file_path), entry.name)
            zip_file.extract(entry, output_path) { true }
          end
        end
      rescue
        next
      end
    end
  end

  def save_file(content, file_name, path, extension)
    FileUtils.mkdir_p "#{storehouse}store/#{keeper.run_id}/#{path}"
    file_storage_path = "#{storehouse}store/#{keeper.run_id}/#{path}/#{file_name}.#{extension}"
    File.open(file_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def get_downloaded_files(sub_folder)
    begin
      files = peon.list(subfolder: "#{keeper.run_id}/#{sub_folder}")
      files.map{ |e| e.split('.')[0...-1].join(' ').scan(/[a-zA-Z0-9]+/).join('_') }
    rescue
      []
    end
  end

  def export_csv_files
    table_keys = ['Annual EM', 'Annual Regents Exams', 'ELP', 'Absenteeism', 'Expenditures', 'Annual NYSAA']
    files = get_files('Report', '*.mdb')
    files.each do |file|
      database = Mdb.open("#{file}")
      table_keys.each do |key|
        required_tables = database.tables.select{ |e| e.split.join.downcase.include? key.split.join.downcase}
        required_tables.each do |table|
          data_hashes = database[table]
          file_name = "#{table.split.join('_').downcase}_#{file.split('/').last.gsub('.','')}"
          csv_file = "#{storehouse}store/#{keeper.run_id}/Report/#{file_name}.csv"
          CSV.open(csv_file, 'w') do |csv|
            csv << data_hashes.first.keys
            data_hashes.each do |record|
              csv << record.values
            end
          end
        end
      end
      file_handling(file, 'a', 'processed')
    end
  end

  def file_handling(content, flag, file_name)
    list = []
    File.open("#{storehouse}store/#{keeper.run_id}/#{file_name}.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write(content.to_s + "\n")
    end
    list unless list.empty?
  end

end
