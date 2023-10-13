# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse_data(page_body, run_id)
    data_array = []
    md5_array = []
    page = parse_html_page(page_body)
    headers = page.css("table[data-cb-name = 'cbTable']").first.css('th').map{ |e| e.text.to_s.downcase }
    table_rows = page.css("table[data-cb-name = 'cbTable']").first.css('tr')[1..]
    table_rows.each do |table_row|
      data_rows = table_row.css('td')
      data_hash = {}
      data_hash[:campus]                  = get_value(data_rows, headers, 'campus')
      data_hash[:department_group]        = get_value(data_rows, headers, 'department group')
      data_hash[:department_group_detail] = get_value(data_rows, headers, 'department group detail')
      data_hash[:department_name]         = get_value(data_rows, headers, 'department name')
      data_hash[:roster_id]               = get_value(data_rows, headers, 'roster id')
      data_hash[:job_title]               = get_value(data_rows, headers, 'job title')
      data_hash[:job_family]              = get_value(data_rows, headers, 'job family')
      data_hash[:job_full_time_pcnt]      = get_value(data_rows, headers, 'job full time pcnt')
      data_hash[:total_funding]           = get_value(data_rows, headers, 'total funding')
      data_hash[:md5_hash]                = create_md5_hash(data_hash)
      data_hash[:run_id]                  = run_id
      data_hash[:touched_run_id]          = run_id
      data_hash[:data_source_url]         = 'https://www.cusys.edu/budget/cusalaries/'
      data_hash                           = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  private

  def parse_html_page(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def get_value(row, headers, key)
    value_index = headers.index(headers.select{ |e| e.include? key }.first)
    row[value_index].text.to_s.squish unless value_index.nil?
  end

end
