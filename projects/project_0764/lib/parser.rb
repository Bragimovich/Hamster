# frozen_string_literal: true

require 'csv'

class Parser < Hamster::Parser
  def parse_csv_data(file)
    header_keys = {
      'Fiscal Year'         => :fiscal_year,
      'Agency'              => :agency,
      'Pay Class Category'  => :pay_class_category,
      'Pay Scale Type'      => :pay_scale_type,
      'Position Number'     => :position_number,
      'Position Title'      => :position_title,
      'Extra Help Flag'     => :extra_help_flag,
      'Class Code'          => :class_code,
      'Employee Name'       => :employee_name,
      'Career Service Date' => :career_service_date,
      'Pay Grade'           => :pay_grade,
      'Gender'              => :gender,
      'Race'                => :race,
      'Percent of Time'     => :percent_of_time,
      'Annual Salary'       => :annual_salary
    }

    csv_data = CSV.read(file, encoding: 'ISO-8859-1:UTF-8')
    raise 'CSV file is empty.' if csv_data.count.zero?

    headers = csv_data.shift.map { |header| header_keys[header] }
    raise 'CSV headers changed! Check the CSV format again.' if headers.any?(&:nil?)

    data = csv_data.map do |row|
      hash = Hash[headers.zip(row)]

      hash[:career_service_date] =
        Date.strptime(hash[:career_service_date], '%Y-%m-%d').strftime('%Y-%m-%d') rescue nil

      hash[:extra_help_flag] = hash[:extra_help_flag].present? ? true : nil

      hash
    end

    data
  end

  def parse_download_csv_link(html_body)
    match_data = /<a[^>]+id="download_button_csv"[^>]*>/.match(html_body)
    if match_data.nil? || match_data.size < 1
      raise "Could not find download link in HTML body.\n#{html_body}"
    end

    link_tag = match_data[0]
    match_data = /href="([^"]+)"/.match(link_tag)
    if match_data.nil? || match_data.size < 2
      raise "Could not get the download link.\n#{link_tag}"
    end

    match_data[1]
  end

  def parse_fiscal_year_links(json)
    obj = parse_json(json.gsub(/^\(|\)$/, ''))
    unless obj['success']
      logger.info 'Failed to parse fiscal years.'
      logger.info json
      raise 'Failed to parse fiscal years.'
    end

    frag = Nokogiri::HTML(obj['data'])
    frag.xpath('//select[@id="fiscal_year_selector"]/option').map { |el| [el.text, el[:value]] }
  end

  private

  def parse_json(json)
    JSON.parse(json)
  rescue => e
    logger.info 'Failed to parse JSON.'
    logger.info json
    raise e
  end
end
