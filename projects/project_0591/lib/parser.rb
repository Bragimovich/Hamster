# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def get_table_rows(page)
    page.css('table.gv-table-view tbody tr')
  end

  def parse_data(page_body, source_link, run_id, inserted_md5)
    data_array = []
    page = parse_page(page_body)
    table_rows = get_table_rows(page)
    t_heads = page.css('table.gv-table-view thead th').map{|e| e.text.downcase.squish}
    table_rows.each do |row|
      data_hash = {}
      date                            = get_td_value(row, t_heads, 'admit date')
      data_hash[:bar_number]          = get_td_value(row, t_heads, 'bar number')
      data_hash[:law_firm_city]       = get_td_value(row, t_heads, 'city')
      data_hash[:law_firm_state]      = get_td_value(row, t_heads, 'state')
      data_hash[:type]                = get_td_value(row, t_heads, 'member type')
      data_hash[:registration_status] = get_td_value(row, t_heads, 'member status')
      data_hash[:date_admitted]       = get_date_required_format(date)
      data_hash[:md5_hash]            = create_md5_hash(data_hash)
      data_hash[:first_name]          = get_td_value(row, t_heads, 'first name')
      data_hash[:middle_name]         = get_td_value(row, t_heads, 'middle name')
      data_hash[:last_name]           = get_td_value(row, t_heads, 'last name')
      data_hash[:name]                = get_full_name(data_hash)
      data_hash[:run_id]              = run_id
      data_hash[:touched_run_id]      = run_id
      data_hash[:data_source_url]     = source_link
      data_hash                       = mark_empty_as_nil(data_hash)
      data_array << data_hash
    end
    md5_array = get_md5_array(data_array)
    data_array = reject_already_inserted_records(data_array, inserted_md5)
    data_array = delete_md5_key(data_array, :md5_hash)
    [data_array,md5_array]
  end

  private

  def get_td_value(row, t_heads, key)
    row.css('td')[t_heads.index(key)].text.strip
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty?) ? nil : value.to_s.squish}
  end

  def get_md5_array(data_array)
    data_array.map{|data_hash| data_hash[:md5_hash]}
  end

  def reject_already_inserted_records(data_array, md5_array)
    data_array.reject{|data_hash| md5_array.include? data_hash[:md5_hash]}
  end

  def get_date_required_format(date)
    DateTime.strptime(date,"%m/%d/%Y").to_date
  end

  def get_full_name(data_hash)
    "#{data_hash[:first_name]} #{data_hash[:middle_name]} #{data_hash[:last_name]}"
  end

  def delete_md5_key(data_array,key)
    return data_array.each{|data_hash| data_hash.delete(key)} unless data_array.empty?
    data_array
  end

end
