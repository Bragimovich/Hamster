# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse_page(response)
    begin
      Nokogiri::HTML(response.force_encoding("utf-8"))  
    rescue StandardError => e
      Nokogiri::HTML(response.body.force_encoding("utf-8"))
    end
  end

  def get_main_body(main_page)
    vs = main_page.css("#__VIEWSTATE")[0]['value']
    vs_generator = main_page.css("#__VIEWSTATEGENERATOR")[0]['value']
    event_validator = main_page.css("#__EVENTVALIDATION")[0]['value']
    [vs, vs_generator, event_validator]
  end

  def get_string_values(pp)
    value = pp.css('text()').select{|e| e.text.include? "EVENTVALIDATION"}.first.text
    event_validator = search_string(value, '__EVENTVALIDATION')
    vs = search_string(value, '__VIEWSTATE')
    vs_generator = search_string(value, '__VIEWSTATEGENERATOR')
    [vs, vs_generator, event_validator]
  end

  def get_year(main_page)
    main_page.css("#ContentPlaceHolder1_ddlstYear")[0].css('option').map {|a| a.text}
  end

  def get_rows(pp)
    pp.css('#ContentPlaceHolder1_gvwSalary').first.css('tr')[3..-3]
  end

  def next_page_exists?(pp, page_num)
    table = pp.css('table').select{|e| e.text.include? "Page:"}.last
    flag = true
    if !table.css('td').select{|e| e.text == "#{page_num}"}.empty?
      flag = false
    elsif (table.css('td').select{|e| e.text == "#{page_num}"}.empty?) and (table.css('td')[-2].css('a')[-1]['href'].include? "#{page_num}")
      flag = false
    end
    flag
  end

  def process_rows(page, year, run_id)
    data_hash = {}
    data_hash[:institution]               = data_fetcher(page, 'Institution:')
    data_hash[:name]                      = page.css('table.popup th').children.first.text.strip
    data_hash[:position]                  = data_fetcher(page, 'Position:')
    data_hash[:title]                     = data_fetcher(page, 'Title:') == " " || data_fetcher(page, 'Title:') == '' ? nil : data_fetcher(page, 'Title:')
    data_hash[:salary]                    = data_fetcher(page, 'Base Salary:').gsub(/\$|,/, "").to_f
    data_hash[:compensation]              = data_fetcher(page, 'Additional Compensation:').gsub(/\$|,/, "").to_f
    data_hash[:vacation_days]             = data_fetcher(page, 'Vacation Days:').to_f
    data_hash[:sick_days]                 = data_fetcher(page, 'Sick Days:').to_f
    data_hash[:bonuses]                   = data_fetcher(page, 'Bonuses:').to_f
    data_hash[:annuities]                 = data_fetcher(page, 'Annuities:').to_f
    data_hash[:retirement_enhancements]   = data_fetcher(page, 'Retirement Enhancements:').to_f
    data_hash[:tuition_waivers]           = data_fetcher(page, 'Tuition Waivers:').to_f
    data_hash[:benefits]                  = data_fetcher(page, 'Other Benefits:').to_f
    data_hash[:employment_status]         = data_fetcher(page, 'Employment Status:')
    data_hash[:employment_classification] = data_fetcher(page, 'Employment Classification:')
    data_hash[:year]                      = year
    data_hash.merge!(common_columns(data_hash, run_id))
    data_hash
  end

  private

  def common_columns(date_hash, run_id)
    {
      md5_hash:              create_md5_hash(date_hash),
      data_source_url:       'https://salarysearch.ibhe.org/search.aspx',
      run_id:                run_id, 
      touched_run_id:        run_id
    }  
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def data_fetcher(pp, search_text)
    values = pp.css('td').select{|e| e.text == search_text}
    unless values.empty?
      values.first.next_element.text.squish
    else
      nil
    end
  end

  def search_string(value, search_text)
    ind = value.split('|').index search_text
    value.split('|')[ind+1]
  end
end
