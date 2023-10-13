# frozen_string_literal: true

class Parser < Hamster::Parser

  def get_event_values_and_years(response)
    page = parse_html(response)
    event_val = search_event_value(page, '#__EVENTVALIDATION')
    view_state = search_event_value(page, '#__VIEWSTATE')
    view_state_gen = search_event_value(page, '#__VIEWSTATEGENERATOR')
    years = page.css('#MainContent_uxEmpYearList').first.css('option').map{|e| e.text.strip}.reject{|e| e.include? 'Select'}
    [event_val,view_state,view_state_gen,years]
  end

  def search_event_value(page, key)
    page.css(key).first['value'] rescue nil
  end

  def parse_data(file,run_id)
    rows = CSV.parse(File.read(file, encoding: "ISO-8859-1"),liberal_parsing: true)
    headers = rows.first.reject{|e| e.nil?}.map{|e| e.to_s.downcase}
    fiscal_year = file.split('/').last.gsub('.csv','')
    data_array = []
    md5_array = []
    rows.each_with_index do |row,index|
      next if (index == 0)
      data_hash = {}
      data_hash[:fiscal_year] = fiscal_year
      data_hash[:agency_number] = get_value(row,headers,'agency_number')
      data_hash[:agency_name] = get_value(row,headers,'agency_name')
      data_hash[:employee_name] = get_value(row,headers,'employee_name')
      data_hash[:job_title] = get_value(row,headers,'job_title')
      data_hash[:total_gross_pay] = get_value(row,headers,'total_gross_pay')
      data_hash[:overtime_pay] = get_value(row,headers,'overtime_pay')
      data_hash[:pay_rate] = get_value(row,headers,'pay_rate')
      data_hash[:frequency] = get_value(row,headers,'frequency')
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:data_source_url] = 'http://kanview.ks.gov/DataDownload.aspx'
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  private

  def get_value(row,headers,key)
    value_index = headers.index(headers.select{ |e| e.include? key }.first)
    row[value_index].to_s.squish unless value_index.nil?
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def parse_html(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
