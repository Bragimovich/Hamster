# frozen_string_literal: true

class Parser < Hamster::Parser
  
  def parse_page(response)
    Nokogiri::HTML(response.force_encoding('utf-8'))
  end

  def captcha_page?(page)
    page.css("th").select{|e| e.text.include? 'Firm Name:'}.empty? ? true : false
  end

  def get_ids(response)
    page = parse_page(response)
    page.css('.table tr')[1...-1].map{ |e| e['onclick'].split('=').last.gsub("'","") } rescue []
  end

  def get_total_pages(response)
    page = parse_page(response)
    (page.css('table.table tr').last.text.squish.scan(/\d+/).first.to_i / 10) + 1
  end

  def get_outer_values(response)
    page = parse_page(response)
    t_heads = page.css('.table th').map{|e| e.text.squish}
    ins_index = get_value_index(t_heads,'Malpractice Insurance')
    disp_index = get_value_index(t_heads,'Discipline: None unless displayed')
    ids = get_ids(response)
    insurance = map_values(page, ins_index)
    discpline = map_values(page, disp_index)
    [ids,insurance,discpline]
  end

  def parse_data(inner_page, id, insurance, discpline, run_id)
    @parsed_page = parse_page(inner_page)
    discpline = get_discipline if (discpline.nil?)
    license_date = get_table_value('license date')
    data_hash = {}
    data_hash[:bar_number]           = id
    data_hash[:name]                 = get_table_value('name')
    data_hash[:date_admitted]        = get_date_format(license_date)
    data_hash[:registration_status]  = get_table_value('license status')
    data_hash[:type]                 = get_table_value('position in firm')
    data_hash[:phone]                = get_table_value('phone')
    data_hash[:law_firm_name]        = get_table_value('firm name')
    data_hash[:law_firm_address]     = get_table_value('address 1')
    if (data_hash[:law_firm_name] == data_hash[:law_firm_address])
      data_hash[:law_firm_address] = get_table_value('address 2')
    end
    data_hash[:law_firm_zip]         = get_table_value('zip/postal')
    data_hash[:law_firm_city]        = get_table_value('city')
    data_hash[:law_firm_state]       = get_table_value('state/province')
    data_hash[:insurance]            = insurance
    data_hash[:disciplinary_actions] = discpline
    data_hash[:md5_hash]             = create_md5_hash(mark_empty_as_nil(data_hash))
    data_hash[:data_source_url]      = "https://mcle.wcc.ne.gov/ext/ViewLawyer.do?id=#{id}"
    data_hash[:run_id]               = run_id
    data_hash[:touched_run_id]       = run_id
    data_hash[:first_name],data_hash[:middle_name],data_hash[:last_name] = name_split(data_hash[:name])
    data_hash                        = mark_empty_as_nil(data_hash)
    data_hash
  end

  def get_md5_array(data_array)
    data_array.map{|data_hash| data_hash[:md5_hash]}
  end

  def delete_md5_key(data_array,key)
    data_array.each{|data_hash| data_hash.delete(key)}
  end

  private

  attr_reader :parsed_page

  def name_split(name)
    last_name = name.split(',').first
    if (name.split.count == 2)
      middle_name = nil
      first_name = name.split.last
    elsif (name.split.count == 3)
      middle_name = name.split.last
      first_name = name.split.second
    elsif (name.split.count == 4)
      middle_name = name.split.last
      first_name = name.split[-3..-2].join(' ')
    end
    [first_name,middle_name,last_name]
  end

  def get_discipline
    parsed_page.at_css('table.table').at_css('tr.DataRow').css('td')[2].text.squish rescue nil
  end

  def get_table_value(key)
    required_row = parsed_page.css("table[width = '95%'] th").select{|e| e.text.downcase.strip.include? key}
    replace_sequence(required_row.first.next_element.text).squish rescue nil
  end

  def replace_sequence(string)
    string.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').squish
  end

  def get_value_index(t_heads, key)
    t_heads.index(key)
  end

  def map_values(page, val_index)
    page.css('.table tr')[1...-1].map{|e| e.css('td')[val_index].text.squish rescue nil}
  end

  def get_date_format(date)
    DateTime.strptime(date,"%m/%d/%Y").to_date rescue nil
  end

  def create_md5_hash(data_hash)
    Digest::MD5.hexdigest data_hash.values * ""
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == 'N/A') ? nil : value.to_s.squish}
  end

end
