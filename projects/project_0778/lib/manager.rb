# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

class Manager < Hamster::Scraper
  def initialize(options)
    super

    @options = options
    @scraper = Scraper.new unless options[:schedules]
    @parser  = Parser.new
    @keeper  = Keeper.new(
      buffer_size: @options[:buffer],
      run_model:   @options[:schedules] ? nil : 'AlCcEmployeeSalariesRun'
    )
  end

  def run
    @options[:schedules] ? run_schedules : run_salaries
  end

  private

  def run_salaries
    start_url  = 'https://www.bscc.edu/about/at-a-glance/financial-data'
    start_html = @scraper.get_content(start_url)
    emp_url    = @parser.parse_start_page(start_html)

    @scraper.reset_connector_cookies
    emp_html = @scraper.get_content(emp_url)
    payload, _, col_vals, year_vals = @parser.parse_employees_page(emp_html, true)

    logger.info "Colleges : #{col_vals}"
    logger.info "Academic Years : #{year_vals}"

    col_vals.each do |col_val|
      year_vals.each do |year_val|
        # fetch page first
        payload['__EVENTTARGET'] = 'AcadYearDDL'
        payload['CollegeDDL']    = col_val[0]
        payload['AcadYearDDL']   = year_val
        payload.delete('DlCsvBtn')

        page_html = @scraper.post_payload(emp_url, payload)
        payload, dl_btn = @parser.parse_employees_page(page_html)
        next if dl_btn.nil?

        # download csv
        payload['__EVENTTARGET'] = ''
        payload['CollegeDDL']    = col_val[0]
        payload['AcadYearDDL']   = year_val
        payload['DlCsvBtn']      = dl_btn

        csv_data = @scraper.post_payload(emp_url, payload)
        csv_data = @parser.parse_employees_csv(csv_data)
        csv_data.each do |data|
          data[:academic_year]   = year_val
          data[:college]         = col_val[1]
          data[:data_source_url] = emp_url

          @keeper.save_data('AlCcEmployeeSalary', data)
        end
      end
    end

    @keeper.flush('AlCcEmployeeSalary')
    @keeper.mark_deleted
    @keeper.finish
  end

  def run_schedules
    csv_file = "#{File.expand_path(File.dirname(__FILE__))}/../sql/salary_schedules.csv"
    @parser.parse_schedules(csv_file) do |schedule|
      @keeper.save_data('AlCcSalarySchedule', schedule)
    end

    @keeper.flush('AlCcSalarySchedule')
  end
end
