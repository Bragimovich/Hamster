# frozen_string_literal: true

class Parser < Hamster::Parser
  def parse_employees_csv(csv)
    header_keys = {
      'empstatus'       => :employee_status,
      'fullname'        => :full_name,
      'initemploy'      => :hire_date,
      'positionaltitle' => :position_title,
      'salsch'          => :salary_schedule,
      'salrank'         => :salary_rank,
      'salstep'         => :salary_step
    }

    csv_data = CSV.parse(csv)
    raise 'CSV is empty.' if csv_data.count.zero?

    headers = csv_data.shift.map { |header| header_keys[header] }
    raise 'CSV headers changed! Check the CSV format again.' if headers.any?(&:nil?)

    data = csv_data.map do |row|
      hash = Hash[headers.zip(row)]

      hire_date = hash[:hire_date]
      hash[:hire_date]   = Date.strptime(hire_date, '%m/%d/%Y').strftime('%Y-%m-%d') rescue nil
      hash[:hire_date] ||= Date.strptime(hire_date, '%Y-%m-%d').strftime('%Y-%m-%d') rescue nil

      hash.each_with_object({}) { |(k, v), h| h[k] = v&.empty? ? nil : v }
    end

    data
  end

  def parse_employees_page(html, include_lists = false)
    doc      = Nokogiri::HTML(html)
    form_els = doc.xpath('//form[@id="form1"]//input[@name][not(@type="submit")]')

    if form_els.size.zero?
      logger.info 'Failed to parse employees page.'
      logger.info html
      raise 'Failed to parse employees page.'
    end

    form_payload =
      form_els.each_with_object({}) do |form_el, h|
        h[form_el[:name]] = form_el[:value]
      end

    download_btn = doc.xpath('//form[@id="form1"]//input[@name="DlCsvBtn"]')
    download_lbl = download_btn.size.zero? ? nil : download_btn[0][:value]

    return [form_payload, download_lbl] unless include_lists

    college_options = doc.xpath('//form[@id="form1"]//select[@name="CollegeDDL"]/option')
    college_values  = college_options.map { |opt| [opt[:value], opt.inner_text] }

    year_options = doc.xpath('//form[@id="form1"]//select[@name="AcadYearDDL"]/option')
    year_values  = year_options.map { |opt| opt[:value] }

    [form_payload, download_lbl, college_values, year_values]
  end

  def parse_schedules(file)
    academic_year = nil
    data_source   = nil
    institution   = nil
    schedule      = nil
    job_type      = nil
    step_count    = 0
    step_names    = []

    csv_data = CSV.read(file)
    csv_data.each do |row|
      command = row.first
      case command
      when 'academic_year'
        academic_year = row[1]
        data_source   = row[2]
      when 'institution'
        institution = row[1]
      when 'schedule'
        schedule = row[1]
        job_type = row[2]
      when 'steps'
        step_count = row[1].to_i
        step_names = row[4..(4 + step_count - 1)]
      else
        rank     = row[0]
        grade    = row[1]
        position = row[2]
        period   = row[3]
        (4..(4 + step_count - 1)).each do |step_idx|
          step = step_names[step_idx - 4]
          val  = row[step_idx]

          entry = {
            academic_year:   academic_year,
            institution:     institution,
            salary_schedule: schedule,
            job_type:        job_type,
            salary_rank:     rank,
            grade:           grade,
            position_title:  position,
            salary_period:   period,
            salary_step:     step,
            value:           val,
            data_source_url: data_source
          }

          entry = entry.each_with_object({}) { |(k, v), h| h[k] = v&.empty? ? nil : v }
          yield entry
        end
      end
    end
  end

  def parse_start_page(html)
    doc       = Nokogiri::HTML(html)
    link_tags = doc.xpath('//div[contains(@class, "underpage")]//div[contains(@class, "content")]//a[text()="Employees"]')

    if link_tags.size.zero?
      logger.info 'Failed to parse first page.'
      logger.info html
      raise 'Failed to parse first page.'
    end

    link_tags[0][:href]
  end
end
