require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Scraper

  def initialize
    super
    @parser = Parser.new
    @keeper = Keeper.new
    @scraper = Scraper.new
    @run_id = keeper.run_id.to_s
    @sub_folder = "#{run_id}/outer_pages"
  end

  def download
    urls_array = []
    urls_array << 'https://www.louisianabelieves.com/resources/library/student-attributes'
    urls_array << 'https://www.louisianabelieves.com/resources/library/elementary-and-middle-school-performance'
    urls_array << 'https://www.louisianabelieves.com/resources/library/school-system-attributes'
    enrollment = scraper.get_file(urls_array[0])
    file_links = parser.find_folder_and_links(enrollment.body, 'Total by', 'enrollment')
    download_files_by_folders(file_links, 'enrollment', )
    save_html_file(enrollment.body, 'enrollment', sub_folder)
    assessment = scraper.get_file(urls_array[1])
    file_links = parser.find_folder_and_links(assessment.body, ['LEA Achievement Level Summary', 'LEA School Achievement Level Summary'] ,'assessment')
    download_files_by_folders(file_links, 'assessment')
    save_html_file(assessment.body, 'assessment', sub_folder)
    file_links = parser.find_folder_and_links(assessment.body, '3-8 Achievement Level Subgroup Summary', 'assessment_by_sub_group')
    download_files_by_folders(file_links, 'assessment_by_sub_group')
    file_links = parser.find_links(assessment.body, 'Kindergarten Assessment')
    download_files(file_links, 'kindergarten')
    discipline_rate = scraper.get_file(urls_array[2])
    file_links = parser.find_links(discipline_rate.body, 'School-District-State Discipline Rates')
    download_files(file_links, 'discipline_rate')
    save_html_file(discipline_rate.body, 'discipline_rate', sub_folder)
    file_links = parser.find_links(discipline_rate.body, 'Discipline Rates by Subgroup')
    download_files(file_links, 'discipline_subgroup')
  end

  def store
    main_path = "#{storehouse}store/#{run_id}"
    la_info_data = keeper.get_data
    enrollment_file = peon.give(subfolder: sub_folder, file: 'enrollment')
    file_links = parser.find_folder_and_links(enrollment_file, 'Total by', 'enrollment')
    all_links = file_links.map { |e| e[:links]}.flatten
    enrollment_folders = peon.list(subfolder: "#{run_id}/enrollment")
    enrollment_folders.each do |folder|
      files = peon.list(subfolder: "#{run_id}/enrollment/#{folder}")
      files.each do |file|
        link = find_link(all_links, file)
        path = "#{main_path}/enrollment/#{folder}/#{file}"
        enrollment_data = parser.parsing_enrollment(path, file, la_info_data, link)
        enrollment_data = enrollment_data.reject { |e| e[:group] == 'Nonprofit Organization' }
        data_insertion(enrollment_data, 'enrollment')
      end
    end
    assesment_file = peon.give(subfolder: sub_folder, file: 'assessment')
    file_links = parser.find_folder_and_links(assesment_file, ['LEA Achievement Level Summary', 'LEA School Achievement Level Summary'] ,'assessment')
    all_links = file_links.map { |e| e[:links]}.flatten
    assessment_folders = peon.list(subfolder: "#{run_id}/assessment")
    assessment_folders.each do |folder|
      files = peon.list(subfolder: "#{run_id}/assessment/#{folder}")
      files.each do |file|
        link = find_link(all_links, file)
        path = "#{main_path}//assessment/#{folder}/#{file}"
        assessment_data = parser.parsing_assessment(path, file, la_info_data, link)
        data_insertion(assessment_data, 'assessment_leap')
      end
    end
    all_links = parser.find_folder_and_links(assesment_file, '3-8 Achievement Level Subgroup Summary', 'assessment_by_sub_group')
    all_links = all_links.map { |e| e[:links]}.flatten
    sub_group_folders = peon.list(subfolder: "#{run_id}/assessment_by_sub_group")
    sub_group_folders.each do |folder|
      files = peon.list(subfolder: "#{run_id}/assessment_by_sub_group/#{folder}")
      files.each do |file|
        link = find_link(all_links, file)
        path = "#{main_path}//assessment_by_sub_group/#{folder}/#{file}"
        subgroup_data = parser.parsing_subgroup(path, file, la_info_data, link)
        data_insertion(subgroup_data, 'assessment_leap_subgroup')
      end
    end
    all_links = parser.find_links(assesment_file, 'Kindergarten Assessment')
    files = peon.list(subfolder: "#{run_id}/kindergarten")
    files.each do |file|
      link = find_link(all_links, file)
      path = "#{main_path}//kindergarten/#{file}"
      kindergarten_data = parser.parsing_kindergarten(path, file, la_info_data, link)
      data_insertion(kindergarten_data, 'kg_entry')
    end
    discipline_rate = peon.give(subfolder:sub_folder, file: 'discipline_rate')
    all_links = parser.find_links(discipline_rate, 'School-District-State Discipline Rates')
    files = peon.list(subfolder: "#{run_id}/discipline_rate")
    files.each do |file|
      link = find_link(all_links, file)
      path = "#{main_path}//discipline_rate/#{file}"
      discipline_rate_data = parser.parsing_discipline_rate(path, file, la_info_data, link)
      data_insertion(discipline_rate_data, 'discipline_rate')
    end
    all_links = parser.find_links(discipline_rate, 'Discipline Rates by Subgroup')
    files = peon.list(subfolder: "#{run_id}/discipline_subgroup")
    files.each do |file|
      link = find_link(all_links, file)
      path = "#{main_path}//discipline_subgroup/#{file}"
      discipline_subgroup_data = parser.parsing_discipline_subgroup(path, file, la_info_data, link)
      data_insertion(discipline_subgroup_data, 'discipline_ethnicity_grade')
    end
    files = peon.list(subfolder: "#{run_id}/discipline_subgroup")
    files.each do |file|
      link = find_link(all_links, file)
      path = "#{main_path}//discipline_subgroup/#{file}"
      discipline_reason = parser.discipline_reason(path, file, la_info_data, link)
      data_insertion(discipline_reason, 'discipline_reason')
    end
    keeper.mark_delete
    keeper.finish
  end

  private

  def data_insertion(data, model)
    keeper.insert_data(data, model) unless data.empty?
  end

  def download_files_by_folders(file_links, sub_folder)
    file_links.each do |link_hash|
    inner_folder = link_hash[:period].gsub("-", "_").gsub('–', '_').squish
      links = link_hash[:links]
      links.each do |link|
        file = scraper.get_file(link)
        file_name = link.split('=').last
        save_file(file.body, file_name, "#{sub_folder}/#{inner_folder}")
      end
    end
  end

  def find_link(all_links, file)
    link = all_links.select { |e| e.include? file.gsub('.xlsx', '') }
    link = all_links.select { |e| e.include? file.gsub('.xls', '') } if link.empty?
    link
  end

  def download_files(file_links, sub_folder)
    file_links.each do |link|
      file = scraper.get_file(link)
      file_name = link.split('=').last
      save_file(file.body, file_name, sub_folder)
    end
  end

  def save_file(file, file_name, sub_folder)
    FileUtils.mkdir_p "#{storehouse}store/#{run_id}/#{sub_folder}"
    pdf_storage_path = "#{storehouse}store/#{run_id}/#{sub_folder}/#{file_name}.xlsx"
    File.open(pdf_storage_path, "wb") do |f|
      f.write(file)
    end
  end

  def save_html_file(html, file_name, subfolder)
    peon.put content: html, file: file_name, subfolder: subfolder
  end

  attr_accessor :keeper, :parser, :scraper, :run_id, :sub_folder
end
