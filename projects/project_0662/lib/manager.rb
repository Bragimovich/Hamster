require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/manager_helper'

class Manager < Hamster::Harvester
  include ManagerHelper
  def initialize(**params)
    super
    @parser     = Parser.new
    @keeper     = Keeper.new
    @scraper    = Scraper.new
    @sub_folder = "Run_ID_#{@keeper.run_id}"
  end

  def download
    @already_downloaded_links = keeper.get_urls
    cmas_data("/assessment/cmas-dataandresults", "cmas results", "view")
    psat_data("/assessment/sat-psat-data", "psat and sat district and school summary achievement", "sat_psat")
    dropout_data("/cdereval/rvprioryeardropoutdata", "dropout statistics")
    graduation_data("/cdereval/rvprioryeargraddata")
    attendance_data("/cdereval/truancystatistics", "truancy rates")
    salary_student_data("/cdereval/rvprioryearhrdata", "staff data", "/cdereval/staffcurrent")
    suspension_data("/cdereval/rvprioryearsdidata", "suspension/expulsion", "suspend-expel")
  end

  def store
    get_ids     = keeper.get_ids
    folders     = peon.list(subfolder: sub_folder)
    folders.each do |folder|
      files = peon.list(subfolder: "#{sub_folder}/#{folder}")
      files.each do |file|
        next if file.include? "lock"
        path = "#{storehouse}store/#{sub_folder}/#{folder}/#{file}"
        case folder
        when /psat|cmas/
          keeper.store_data(insert_data(path, file, folder, get_ids), folder, 0)
        when /dropout/
          keeper.store_data(insert_record(path, file, get_ids, 0, 0), folder, 0)
          keeper.store_data(insert_record(path, file, get_ids, 1, 1), folder, 1)
        when /graduation/
          keeper.store_data(insert_record(path, file, get_ids, 1, 0), folder, 0)
          keeper.store_data(insert_record(path, file, get_ids, 0, 1), folder, 1)
        when /attendance/
          keeper.store_data(parser.get_data_attendance(path, keeper.run_id, file, get_ids), folder, 0)
        when /salary/
          keeper.store_data(parser.get_data_salary(path, keeper.run_id, file, get_ids), folder, 0)
        when /student/
          keeper.store_data(parser.get_student_ratio(path, keeper.run_id, file, get_ids), folder, 0)
        when /suspension/
          keeper.store_data(parser.get_safety(path, keeper.run_id, file, get_ids), folder, 0)
        end
      end
    end
    keeper.finish
  end

  private
  attr_accessor :parser, :keeper, :sub_folder, :scraper

  def insert_data(path, file, folder, get_ids)
    parser.get_data(path, keeper.run_id, file, folder, get_ids)
  end

  def insert_record(path, file, get_ids, flag, flag_1)
    (flag_1 == 0)? parser.get_race(path, keeper.run_id, file, "race", get_ids, flag) :  parser.get_social(path, keeper.run_id, file, "ipst", get_ids, flag)
  end

  def download_inner_xls(link, selector, appender)
    parser.get_inner_links(get_main_page(link), selector, appender)
  end

  def download_xls(link, selector, folder)
    links = parser.get_links(get_main_page(link), selector)
    get_xls(links, folder)
  end

  def get_xls(links, folder_name)
    links.each do |link|
      next if !(@already_downloaded_links.select{ |a| a.include? link.gsub("_","/")}.empty?)
      file_name  = link.gsub("/","_")
      xls_result = scraper.get_xls(link)
      save_xlxs(xls_result.body, file_name, folder_name)
    end
  end

  def get_main_page(link)
    main_page = scraper.get_xls(link)
    parser.parse_html(main_page.body)
  end

  def save_xlxs(content, file_name, folder_name)
    FileUtils.mkdir_p "#{storehouse}store/#{sub_folder}/#{folder_name}"
    zip_storage_path = "#{storehouse}store/#{sub_folder}/#{folder_name}/#{file_name}.xlsx"
    File.open(zip_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html.body, file: "#{file_name}", subfolder: sub_folder
  end
end
