require 'fileutils'

class Scraper < Hamster::Scraper

  def initialize
    super
    @cobble = Dasher.new(using: :cobble, redirect: true)
    @domain = 'https://www.in.gov'

    @peon = Peon.new(storehouse)
  end

  def data_center_page
    url = 'https://www.in.gov/doe/it/data-center-and-reports/'
    @cobble.get(url)
  end

  def data_archive_page
    url = 'https://www.in.gov/doe/it/data-center-and-reports/data-reports-archive/'
    @cobble.get(url)
  end

  def get_general_info(data_center_html)

    document = Nokogiri::HTML data_center_html

    title_for_general_file = document.css("h2:contains('General School Information')").first.next_element
    path_for_download_file = title_for_general_file.css('li > a')[0]['href']

    download_files([].push(path_for_download_file), 'general')
    logger.info "*************** Download General Data ***************"
  end

  def move_files_to_dst_dir(file_name, target_dis)
    if File.exist?("#{storehouse}store/#{file_name}")
      unless Dir.exist?("#{storehouse}store/#{target_dis}") then Dir.mkdir("#{storehouse}store/#{target_dis}") end
      FileUtils.move("#{storehouse}store/#{file_name}", "#{storehouse}store/#{target_dis}")
    else
      logger.error "can not find source file to move"
    end
  end

  def download_files(arr_paths, target_dis)
    arr_paths.each do |path|
      url = path.include?(@domain) ? path : URI(@domain + path)
      file_name = path.include?(@domain) ? "#{path[29..]}".downcase : "#{path[11..]}".downcase
      @cobble.get_file(url, filename: file_name)
      move_files_to_dst_dir(file_name, target_dis)
    end
  end

  # ===== ENROLLMENT SECTION =====
  # Download data from
  def get_attendance_enrollment_info(data_center_html)
    document = Nokogiri::HTML data_center_html

    arr_paths = []
    download_files_list = document.css("h2:contains('Attendance & Enrollment')").first.next_element
    download_files_list.css('li > a').each do |link|

      if link.content == 'Corporation Enrollment by Ethnicity and Free/Reduced Price Meal Status' or
        link.content == 'Corporation Enrollment by Special Education and English Language Learners (ELL)' or
        link.content == 'Corporation Enrollment by Grade Level and Gender' or
        link.content == 'School Enrollment by Ethnicity and Free/Reduced Price Meal Status' or
        link.content == 'School Enrollment by Special Education and English Language Learners (ELL)' or
        link.content == 'School Enrollment by Grade Level and Gender'

        arr_paths.push(link['href'])
      end
    end
    download_files(arr_paths, 'enrollment')
    logger.info "*************** Download Enrollment Data ***************"
  end

  # ===== ASSESSMENT SECTION =====
  # ======= ILEARN =======
  # Save data to in_schools_assessment and in_schools_assessment_by_levels tables
  def get_ilearn_assessment(data_center_html, data_archive_html)

    document_data_center = Nokogiri::HTML data_center_html
    document_data_archive = Nokogiri::HTML data_archive_html

    arr_paths = []

    # Parser files from Data Center & Reports page
    # Need to replace the year for the first file to exclude it.

    document_data_center.css("div[class='primary callout'] > ul > li > a").each do |link|
      if link.content != '2022 ILEARN Grade 3-8 Statewide Summary Results'
        arr_paths.push(link['href'])
      end
    end

    # Parser files from Data Reports Archive page
    ilearn_archive = document_data_archive.css("div#ILEARN")

    ilearn_archive.css('h4').each do |year|
      ilearn_archive.css("h4:contains(#{year.text}) + ul > li > a").each do |link|
        if link.content != "#{year.text} ILEARN Grade 3-8 Statewide Summary Results"
          arr_paths.push(link['href'])
        end
      end
    end

    download_files(arr_paths, 'ilearn')
    logger.info "*************** Download ILEARN Data ***************"
  end

  # ======= ISTEP+ =======
  # Download data from "Data center and Reports" and "Data Archive"
  def get_istep_plus_assessment(data_center_html, data_archive_html)

    document_data_center = Nokogiri::HTML data_center_html
    document_data_archive = Nokogiri::HTML data_archive_html

    arr_paths = []

    # Parser files from Data Center & Reports page
    document_data_center.css("div[class='success callout'] > ul > li > a").each do |link|
      if link.content != '2021 ISTEP+ Grade 10 State Summary Results'
        arr_paths.push(link['href'])
      end
    end

    # Parser files from Data Reports Archive page
    istep = document_data_archive.css("div#ISTEP_")

    istep.css('h4').each do |year|
      unless ['2016', '2015', '2014'].include?(year.text)
        istep.css("h4:contains(#{year.text}) + ul > li > a").each do |link|
          if link.content != "#{year.text} ISTEP+ Grade 10 Statewide Summary Results"
            arr_paths.push(link['href'])
          end
        end
      end
    end

    download_files(arr_paths, 'istep')
    logger.info "*************** Download ISTEP+ Data ***************"
  end

  # ======= I AM  Alternate =======
  # Download data from "Data center and Reports" and "Data Archive"
  def get_i_am_alternate_assessment(data_center_html, data_archive_html)

    document_data_center = Nokogiri::HTML data_center_html
    document_data_archive = Nokogiri::HTML data_archive_html

    arr_paths = []

    # Parser files from Data Center & Reports page
    document_data_center.css("div[class='alert callout'] > ul > li > a").each do |link|
        arr_paths.push(link['href'])
    end

    # Parser files from Data Reports Archive page
    i_am = document_data_archive.css("div#I_AM")
    i_am.css('h4').each do |year|
      if year.text != '2021'
        i_am.css("h4:contains(#{year.text}) + ul > li > a").each { |link| arr_paths.push(link['href']) }
      end
    end

    download_files(arr_paths, 'i_am')
    logger.info "*************** Download I AM Data ***************"
  end

  # ======= IREAD-3 =======
  # Download data from "Data center and Reports" and "Data Archive"
  def get_iread_3_assessment(data_center_html, data_archive_html)

    document_data_center = Nokogiri::HTML data_center_html
    document_data_archive = Nokogiri::HTML data_archive_html

    arr_paths = []

    # Parser files from Data Center & Reports page
    document_data_center.css("div[class='warning callout'] > ul > li > a").each do |link|
        arr_paths.push(link['href'])
    end

    # Parser files from Data Reports Archive page
    iread3 = document_data_archive.css("div#IREAD_3")
    iread3.css('h4').each do |year|
      if year.text != '2016 - Spring & Summer'
        iread3.css("h4:contains(#{year.text}) + ul > li > a").each { |link| arr_paths.push(link['href']) }
      end
    end

    download_files(arr_paths, 'iread3')
    logger.info "*************** Download IREAD-3 Data ***************"
  end

  # ======= SAT =======
  # Download data from "Data center and Reports"
  def get_sat_grade_11(html)
    document = Nokogiri::HTML html

    arr_paths = []

    # Parser files from Data Center & Reports page
    download_files_list = document.css("h2:contains('SAT Grade 11')").first.next_element
    download_files_list.css('li > a').each do |link|
      arr_paths.push(link['href'])
    end

    download_files(arr_paths, 'sat')
    logger.info "*************** Download SAT Data ***************"
  end

end