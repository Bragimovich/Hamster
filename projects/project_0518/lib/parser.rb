# frozen_string_literal" => true
class Parser < Hamster::Parser

  def increase_per_page_records(response)
    data = Nokogiri::HTML(response)
    number_results_dropdown = data.css("select.rows-per-page")[0]
    number_results_dropdown_id = number_results_dropdown["id"]
    number_results_dropdown_x_value = "?x=" + number_results_dropdown["onchange"].split("?x=")[-1].split("'").first
    [number_results_dropdown_x_value, number_results_dropdown_id]
  end

  def case_type_tab_selection(response)
    data = Nokogiri::HTML(response)
    case_type_tab = data.css("a").select{|s| s.text == "Case Type"}[0]
    case_type_tab_id = case_type_tab["id"]
    case_type_tab_x_value = "?x=" + case_type_tab["onclick"].split("?x=")[-1].split("'").first
    [case_type_tab_x_value, case_type_tab_id]
  end

  def fetch_date_x_value(response)
    data = Nokogiri::HTML(response)
    begin_date = data.css("div.beginDate input")[0]
    begin_date_x_value = "?x=" + begin_date["onchange"].split("?x=")[-1].split("'").first
    end_date = data.css("div.endDate input")[0]
    end_date_x_value = "?x=" + end_date["onchange"].split("?x=")[-1].split("'").first
    [begin_date_x_value, end_date_x_value]
  end

  def get_values_for_case_types(response)
    data = Nokogiri::HTML(response)
    case_type_dropdown = data.css("select[name='caseCd']")[0]
    case_type_dropdown_id = case_type_dropdown["id"]
    case_type_dropdown_x_value = "?x=" + case_type_dropdown["onchange"].split("?x=")[-1].split("'").first
    [case_type_dropdown_x_value, case_type_dropdown_id]
  end

  def fetch_case_types(response)
    data = Nokogiri::HTML(response)
    data.css('select')[0].css('option').map { |e| e['value']}
  end

  def form_x_value(response)
    data = Nokogiri::HTML(response)
    form = data.css("form")[0]
    form_x_value = "?x=" + form["action"].split("?x=")[-1].split('"').first
    form_x_value
  end

  def get_pagination_links(response)
    data = Nokogiri::HTML(response)
    data.css('.navigator a')[0..-3].map { |e| ['?x=' + e['onclick'].split('?x=')[1].split("'")[0], e['id']] }.uniq
  end

  def get_inner_links_for_pagination(response, case_type)
    data = Nokogiri::HTML(response)
    data.css('tbody tr').map{|e| e.css('td').select{|s| s.text.include? case_type.strip}.first}.map{|e| [e.css('a').first['href'], e.css('a').text]}
  end

  def find_x_value(response)
    data = Nokogiri::HTML(response)
    data.css("form")[0]["action"]
  end

  def get_values(response)
    data    = Nokogiri::HTML(response)
    form    = data.css("form")[0]
    form_id = form["id"]
    x_value = data.css(".anchorButton")[0]["onclick"].split("?x=")[-1].split("'")[0]
    x_value = "?x=#{x_value}"
    captcha_image_url =  data.css("img")[0]["src"]
    [form_id, x_value, captcha_image_url]
  end

# Parsing STARTS FOMR HERE

  def parse(html, run_id)
    page                  = Nokogiri::HTML(html)
    case_id               = page.css('.caseHdrTitle').text.split('  ')[0].squish
    case_info_array       = get_case_info(page, run_id, case_id)
    case_parties_array    = get_case_party(page, run_id, case_id)
    case_judgement_array  = get_case_judgement(page, run_id, case_id)
    case_activities_array = get_case_activities(page, run_id, case_id)
    [case_info_array, case_parties_array, case_judgement_array, case_activities_array]
  end

  private

  def get_case_info(page, run_id, case_id)
    case_info_array = []
    data_hash       = {}
    data            = page.css('#caseHeader ul')
    data_hash[:court_id]              = 500
    data_hash[:case_id]               = case_id
    data_hash[:case_name]             = page.css('.caseHdrTitle').text.split('  ').last.squish
    data_hash[:case_filed_date]       = get_date(search_value(data, 'file date:'))
    data_hash[:case_type]             = search_value(data, 'case type:')
    data_hash[:disposition_or_status] = page.css("#dispositionInfo td")[0].text
    data_hash[:status_as_of_date]     = search_value(data, 'case status:')
    data_hash[:judge_name]            = search_value(data, 'case judge:')
    data_hash                         = mark_empty_as_nil(data_hash) unless data_hash.nil?
    data_hash[:md5_hash]              = create_md5_hash(data_hash)
    data_hash[:run_id]                = run_id
    data_hash[:touch_run_id]          = run_id
    data_hash[:data_source_url]       = 'https://eaccess.k3county.net/eservices/search.page.22'
    case_info_array << data_hash
    case_info_array
  end

  def get_case_activities(page, run_id, case_id)
    data_array = []
    activities =  page.css('#docketInfo tbody tr')
    return [] if activities.empty?
    activities.each do |activity|
      data_hash = {}
      data_hash[:court_id]        = 500
      data_hash[:case_id]         = case_id
      data_hash[:activity_date]   = get_date(activity.css("td")[0].text)
      data_hash[:activity_decs ]  = activity.css("td")[1].text
      data_hash                   = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:run_id]          = run_id
      data_hash[:touch_run_id]    = run_id

      data_hash[:data_source_url] = "https://eaccess.k3county.net/eservices/search.page.22"
      data_array << data_hash
    end
    data_array
  end

  def get_case_judgement(page, run_id, case_id)
    data_array = []
    events     = page.css('#eventInfo tbody tr')
    return [] if events.empty?
    events.each do |event|
      data_hash = {}
      data_hash[:court_id]        = 500
      data_hash[:case_id]         = case_id
      data_hash[:party_name]      = event.css("td")[3].text
      data_hash[:fee_amount]      = event.css("td")[2].text
      data_hash[:judgment_amount] = event.css("td")[1].text
      data_hash[:judgment_date]   = get_date(event.css("td")[0].text.split.first)
      data_hash                   = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash]        = create_md5_hash(data_hash)
      data_hash[:run_id]          = run_id
      data_hash[:touch_run_id]    = run_id
      data_hash[:data_source_url] = "https://eaccess.k3county.net/eservices/search.page.22"
      data_array << data_hash
    end
    data_array
  end

  def get_case_party(page, run_id, case_id)
    party_hash_array = []
    party_action = search_value(page, 'action:')
    party_css = page.css('#ptyContainer')
    non_lawyer_parties = (party_css.css('div.rowodd') + party_css.css('div.roweven')).select {|e| e.text.include? 'Party Attorney'}
    non_lawyer_parties.each do |party|
      party_data = fetch_non_lawyer_data(party)
      party_hash_array << party_hash(party_data, run_id, case_id, party_action, 0)
    end
    lawyer_parties = (party_css.css('div.rowodd') + party_css.css('div.roweven')).reject {|e| e.text.include? 'Party Attorney'}
    lawyer_parties.each do |party|
      party_data = fetch_lawyer_info(party)
      party_hash_array << party_hash(party_data, run_id, case_id, party_action, 1)
    end
    party_hash_array
  end

  def fetch_lawyer_info(party)
    party_data = []
    data = party.css("ul")
    party_data << search_value(data, 'attorney')
    party_data << party.parent.parent.parent.css('.ptyType').text.gsub('-', '').squish
    party_data << nil
    party_data << search_value(data, 'bar code')
    party_data << search_value(data, 'phone')
    party_data = party_data + get_address_info(data)
    party_data
  end

  def fetch_non_lawyer_data(party)
    party_data = []
    party_data << party.css('.ptyInfoLabel').text.squish
    party_data << party.css('.ptyType').text.gsub('-', '').squish
    party_data << search_value(party.css('.displayData ul'), 'dob')
    party_data
  end

  def party_hash(data, run_id, case_id, party_action, is_lawyer)
    data_hash = {}
    data_hash[:court_id]        = 500
    data_hash[:case_id]         = case_id
    data_hash[:is_lawyer]       = is_lawyer
    data_hash[:party_name]      = data[0]
    data_hash[:party_type]      = data[1]
    data_hash[:party_dob]       = data[2].to_date rescue nil
    data_hash[:party_law_firm]  = data[5]
    data_hash[:party_address]   = data[6]
    data_hash[:party_city]      = data[7]
    data_hash[:party_state]     = data[8]
    data_hash[:party_zip]       = data[9]
    data_hash[:barcode]         = data[3]
    data_hash[:phone]           = data[4]
    data_hash[:party_action]    = party_action
    data_hash                   = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash]        = create_md5_hash(data_hash)
    data_hash[:run_id]          = run_id
    data_hash[:touch_run_id]    = run_id
    data_hash[:data_source_url] = "https://eaccess.k3county.net/eservices/search.page.22"
    data_hash
  end

  def get_address_info(data)
    address = data.select {|e| e.text.downcase.include? 'address'}[0].css('li.ptyAttyInfo')
    return [] if address.empty?
    city           = address.css('span')[0].text
    state          = address.css('span')[2].text
    zip            = address.css('span').last.text
    party_law_firm = (address.css('div')[0].text[/\d/].nil?) ? address.css('div')[0].text : nil
    party_address  = ""
    address        = (party_law_firm.nil?) ? address.css('div') : address.css('div')[1..]
    address.css('div').map  { |e| party_address = party_address + ' ' + e.text}
    [party_law_firm, party_address, city, state, zip]
  end

  def search_value(data, value)
    data.css('li').select { |e| e.text.squish.downcase == value }[0].next_element.text.squish rescue nil
  end

  def get_date(date)
    DateTime.strptime(date, "%m/%d/%Y").to_date rescue nil
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| (value.to_s.empty? or value == 'NA') ? nil : value.to_s.squish }
  end

end
