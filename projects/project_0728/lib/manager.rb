require_relative 'scraper'
require 'csv'
require_relative 'parser'
require_relative 'keeper'

class Manager < Hamster::Scraper

  def initialize(**options)
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
  end

  def download
    process_data("download")
  end

  def store
    process_data("store")
  end

  def process_data(type)
    landing_page = @scraper.fetch_main_page
    return if landing_page.nil?
    array_links_from_main_page = @parser.get_links_from_landing_page(landing_page)
    array_links_from_main_page.each do |query|
      begin
        link =  @scraper.get_aws_link_from_sub_page(query)
        @scraper.save_csv_file(query ,link)
      rescue Exception => e
        Hamster.logger.error(e.full_message)
        Hamster.report(to: 'Farzpal Singh', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
      pdf_paths = Dir["#{storehouse}store/*/*.csv"]
      begin
        csv_file_path = pdf_paths.select { |file| file.include? query.to_s }.first
        if csv_file_path.nil?
          Hamster.report(to: 'Farzpal Singh', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\nError: The specified query #{query} did not match any CSV file paths", use: :slack)
        else
          csv_data = @parser.get_hashes(csv_file_path, query)
          parse_data(csv_data, query, type)
        end
      rescue Exception => e
        Hamster.logger.error(e.full_message)
        Hamster.report(to: 'Farzpal Singh', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
    end
  end

  def parse_data(sub_page_data, id, type)
    if id == 29262
      id_employee_pay_rates(sub_page_data, type)
    elsif id == 31059
      id_agency_heads(sub_page_data, type)
    else
      id_employment_history(sub_page_data, type)
    end

    @keeper.finish
    @keeper.mark_delete
  end

  def id_employee_pay_rates(data, type)
    data.each do |employee_pay_rates|
      id_employee_pay_rates = {
        employee_name: employee_pay_rates['employee_name'],
        job_title: employee_pay_rates['job_title'],
        agency_name: employee_pay_rates['agency_name'],
        pay_rate: employee_pay_rates['pay_rate'],
        pay_basis: employee_pay_rates['pay_basis'],
        full_or_part_status: employee_pay_rates['full_or_part_status'],
        agency_code: employee_pay_rates['agency_code'],
        annual_salary: employee_pay_rates['annual_salary'],
        class_code: employee_pay_rates['class_code'],
        appointment_type: employee_pay_rates['appointment_type'],
        date_of_loads: employee_pay_rates['date_of_load'],
        employee_count: employee_pay_rates['employee_count'],
        work_county: employee_pay_rates['work_county'],
      }

      md5_info = MD5Hash.new(columns:%w[employee_name job_title agency_name pay_rate pay_basis full_or_part_status agency_code annual_salary class_code appointment_type date_of_loads employee_count work_county])
      hash = md5_info.generate(id_employee_pay_rates)

      md5_info_hash = {
        md5_hash: hash,
      }
      data = id_employee_pay_rates.merge!(md5_info_hash)
      if type === 'download'
        @keeper.save_new_data(data, IdEmployeePayRate)
      else
        @keeper.store_run_id(data, IdEmployeePayRate)
      end
    end
  end

  def id_agency_heads(data, type)
    data.each do |agency_heads|
      id_agency_heads = {
        name: agency_heads['employee_name'],
        job_title: agency_heads['job_title'],
        agency_name: agency_heads['agency_name'],
        agency_code: agency_heads['agency_code'],
        annual_salary: agency_heads['annual_salary'],
        date_of_loads: agency_heads['date_of_load'],
      }

      md5_info = MD5Hash.new(columns:%w[name job_title agency_name agency_code annual_salary date_of_loads])
      hash = md5_info.generate(id_agency_heads)
      md5_info_hash = {
        md5_hash: hash,
      }
      data = id_agency_heads.merge!(md5_info_hash)
      if type === 'download'
        @keeper.save_new_data(data, IdAgencyHeads)
      else
        @keeper.store_run_id(data, IdAgencyHeads)
      end
    end
  end

  def id_employment_history(data, type)
    data.each do |employment_history|
      id_employment_history = {
        employee_name: employment_history['employee_name'],
        job_title: employment_history['job_title'],
        agency_name: employment_history['agency_name'],
        pay_rate: employment_history['pay_rate'],
        pay_basis: employment_history['pay_basis'],
        full_or_part_status: employment_history['full_or_part_status'],
        hire_date: employment_history['hire_date'],
        seperation_date: employment_history['seperation_date'],
        months_at_agency: employment_history['months_at_agency'],
        appointment_type: employment_history['appointment_type'],
        status: employment_history['status'],
        prior_record: employment_history['prior_record'],
      }

      md5_info = MD5Hash.new(columns:%w[employee_name job_title agency_name pay_rate pay_basis full_or_part_status hire_date seperation_date months_at_agency appointment_type status prior_record])
      hash = md5_info.generate(id_employment_history)
      md5_info_hash = {
        md5_hash: hash,
      }
      data = id_employment_history.merge!(md5_info_hash)

      if type === 'download'
        @keeper.save_new_data(data, IdEmploymentHistory)
      else
        @keeper.store_run_id(data, IdEmploymentHistory)
      end
    end
  end
end
