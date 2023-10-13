# frozen_string_literal: true

class Parser < Hamster::Parser

  def get_total_pages(response)
    begin
      page = parse_json(response)
      page['total_pages']
    rescue
      nil
    end
  end

  def get_years(response)
    page = Nokogiri::HTML(response.force_encoding('utf-8'))
    page.css('#yearGroup li').map{|e| e.text.squish}
  end

  def parse_data(page_body,year,run_id)
    data_array = []
    md5_array = []
    json_page = parse_json(page_body)
    html_page = parse_html(json_page['html'])
    result_rows = html_page.css('tr').select{|e| e['id'].include? 'result'}
    expanded_rows = html_page.css('tr').select{|e| e['id'].include? 'expand'}
    (0...result_rows.count).each do |value|
      data_hash = {}
      data_hash[:name] = get_result_row_data(result_rows[value],1)
      data_hash[:employer] = get_result_row_data(result_rows[value],2)
      data_hash[:total_pay] = get_result_row_data(result_rows[value],3)
      data_hash[:subagency] = get_result_row_data(result_rows[value],4)
      data_hash[:title] = get_expand_row_data(expanded_rows[value],'title')
      data_hash[:rate_of_pay] = get_expand_row_data(expanded_rows[value],'rateofpay')
      data_hash[:pay_year] = get_expand_row_data(expanded_rows[value],'payyear')
      data_hash[:pay_basis] = get_expand_row_data(expanded_rows[value],'paybasis')
      data_hash[:branch] = get_expand_row_data(expanded_rows[value],'branch')
      data_hash[:year] = year
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:data_source_url] = 'https://www.seethroughny.net/payrolls'
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash = mark_empty_as_nil(data_hash)
      data_array << data_hash
      md5_array << data_hash[:md5_hash]
    end
    [data_array,md5_array]
  end

  private

  def get_expand_row_data(row,key)
    row.css('strong').select{|e| e.text.downcase.split.join.include? key}.first.parent.next_element.text.squish
  end

  def get_result_row_data(row,data_index)
    row.css('td')[data_index].text.squish
  end

  def parse_json(response)
    JSON.parse(response)
  end

  def parse_html(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def get_date_format(date)
    DateTime.strptime(date,"%m/%d/%Y").to_date rescue nil
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
