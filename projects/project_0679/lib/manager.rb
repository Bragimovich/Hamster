# frozen_string_literal: true
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  
  def initialize(**params)
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
  end
  
  def download
    main_response = @scraper.get_response('https://education.alaska.gov/data-center')
    main_page = @parser.parse_page(main_response.body)
    school_district_links = @parser.get_links(main_page,'form4-select')
    download_files(school_district_links,'Enrollment')
    school_enrolment_links = @parser.get_links(main_page,'form5-select')
    download_files(school_enrolment_links,'Enrollment')
    teacher_count_links = @parser.get_links(main_page,'form8-select')
    download_files(teacher_count_links,'Teachers_Count')
    four_year_district_links = @parser.get_links(main_page,'form14-select')
    download_files(four_year_district_links,'Graduation')
    four_year_school_links = @parser.get_links(main_page,'form15-select')
    download_files(four_year_school_links,'Graduation')
    five_year_district_links = @parser.get_links(main_page,'form16-select')
    download_files(five_year_district_links,'Graduation')
    five_year_school_links = @parser.get_links(main_page,'form17-select')
    download_files(five_year_school_links,'Graduation')
    financial_links = @parser.get_links(main_page,'form19-select')
    download_files(financial_links,'Financial')
    download_assessment_district_files
    download_assessment_school_files
  end

  def store
    ids_names = @keeper.get_ids_and_names
    storing_enrolment(ids_names)
    storing_graduation(ids_names)
    storing_revenue(ids_names)
    storing_assessment(ids_names)
    storing_teachers_count(ids_names)
    @keeper.finish
  end

  private

  def download_assessment_district_files
    years = ("#{Date.today.year - 6}".."#{Date.today.year}").map(&:to_i)
    processed_years = get_processed_years("District")
    science_values = ['True','False']
    years.each do |year|
      next if processed_years.include? year
      science_values.each do |value|
        response = @scraper.get_response("https://education.alaska.gov/assessment-results/District/DistrictSelect?schoolYear=#{year}-#{year+1}&isScience=#{value}")
        district_ids = @parser.get_district_ids(response.body)
        district_ids.each do |id|
          response = @scraper.get_response("https://education.alaska.gov/assessment-results/District/DistrictResults?DistrictYear=#{year}-#{year+1}&IsScience=#{value}&DistrictId=#{id}")
          csv_link = @parser.get_csv_link(response.body)
          subfolder = "District/#{year}/"
          download_csv(csv_link,subfolder) unless csv_link.nil?
        end
      end
    end
  end

  def download_assessment_school_files
    years = ("#{Date.today.year - 6}".."#{Date.today.year}").map(&:to_i)
    processed_years = get_processed_years("School")
    science_values = ['True','False']
    years.each do |year|
      next if processed_years.include? 'year'
      science_values.each do |value|
        response = @scraper.get_response("https://education.alaska.gov/assessment-results/Schoolwide/SchoolwideSelect?schoolYear=#{year}-#{year+1}&isScience=#{value}")
        district_ids = @parser.get_district_ids(response.body)
        district_ids.each do |district_id|
          response = @scraper.school_post_request(district_id)
          school_ids = @parser.get_school_ids(response.body)
          school_ids.each do |school_id|
            response = @scraper.get_response("https://education.alaska.gov/assessment-results/Schoolwide/SchoolwideResult?SchoolYear=#{year}-#{year+1}&IsScience=#{value}&DistrictId=#{district_id}&SchoolId=#{school_id}")
            csv_link = @parser.get_csv_link(response.body)
            subfolder = "School/#{year}/"
            download_csv(csv_link,subfolder) unless csv_link.nil?
          end
        end
      end
    end
  end

  def download_csv(csv_link,subfolder)
    domain = 'https://education.alaska.gov'
    file_name = csv_link.scan(/[a-zA-Z0-9]+/).join('_')
    file_type = 'csv'
    response = @scraper.get_response(domain + csv_link)
    saving_file(response.body,file_name,"Assessment/#{subfolder}",file_type)
  end

  def download_files(links,folder)
    already_downloaded_files = get_downloaded_files(folder)
    links.each do |link|
      file_type = link.split('.').last
      file_name = link.scan(/[a-zA-Z0-9]+/).join('_').gsub("_#{file_type}","")
      next if already_downloaded_files.include? file_name
      response = @scraper.get_response("https://education.alaska.gov#{link.gsub(' ','%20')}")
      saving_file(response.body,file_name,folder,file_type)
    end
  end

  def storing_enrolment(ids_names)
    enrolment_files = get_files('Enrollment','*')
    enrolment_files.each do |file|
      data_array = @parser.parse_enrolment_files(file,ids_names,@keeper.run_id)
      @keeper.insert_records(data_array,'enrollment')
    end
  end

  def storing_graduation(ids_names)
    graduation_files = get_files('Graduation','*')
    graduation_files.each do |file|
      data_array = @parser.parse_graduation_files(file,ids_names,@keeper.run_id)
      @keeper.insert_records(data_array,'graduation')
    end
  end

  def storing_revenue(ids_names)
    revenue_files = get_files('Financial','*')
    revenue_files.each do |file|
      data_array = @parser.parse_revenue_files(file,ids_names,@keeper.run_id)
      @keeper.insert_records(data_array,'revenue')
    end
  end

  def storing_assessment(ids_names)
    assessment_files = get_files('Assessment','*.csv')
    assessment_files.each do |file|
      data_array = @parser.parse_assessment_files(file,ids_names,@keeper.run_id)
      @keeper.insert_records(data_array,'assessment')
    end
  end

  def storing_teachers_count(ids_names)
    teachers_count_files = get_files('Teachers_Count','*.xlsx')
    teachers_count_files.each do |file|
      data_array = @parser.parse_teachers_count_files(file,ids_names,@keeper.run_id)
      @keeper.insert_records(data_array,'teacher_count')
    end
  end

  def get_files(folder, file_type)
    Dir["#{storehouse}store/#{@keeper.run_id}/#{folder}/**/#{file_type}"]
  end

  def saving_file(content,file_name,path,type)
    FileUtils.mkdir_p "#{storehouse}store/#{@keeper.run_id}/#{path}"
    file_storage_path = "#{storehouse}store/#{@keeper.run_id}/#{path}/#{file_name}.#{type}"
    File.open(file_storage_path, "wb") do |f|
      f.write(content)
    end
  end

  def get_downloaded_files(path)
    begin
      files = peon.list(subfolder: "#{@keeper.run_id}/#{path}")
      files.map{ |e| e.split('.')[0...-1].join(' ').scan(/[a-zA-Z0-9]+/).join('_') }
    rescue
      []
    end
  end

  def get_processed_years(subfolder)
    peon.list(subfolder: "#{@keeper.run_id}/Assessment/#{subfolder}").map(&:to_i).sort[0...-1] rescue []
  end

end
