# frozen_string_literal: true

class Parser < Hamster::Parser
  def process_page(reponse_page)
    parsed_doc = Nokogiri::HTML.parse(reponse_page)
    field_tags = parsed_doc.xpath('//div[@class="ReadOnly PanelField Left"]')
    tags_to_hash(field_tags)
  end

  def parse_members(response_page, lister_panel_name)
    table_data_idx =
      response_page.find_index do |rd|
        rd[1] == 'updatePanel' &&
          rd[2] == lister_panel_name.gsub('$', '_')
      end

    return [] if table_data_idx.nil?

    table_data  = response_page[table_data_idx]
    update_html = table_data[3]
    update_frag = Nokogiri::HTML.fragment(update_html)

    no_records_row = update_frag.xpath('.//table[contains(@class, "rgMasterTable")]/tbody/tr[contains(@class, "rgNoRecords")]')
    return [[], update_frag] if no_records_row.count.positive?

    member_list = []
    table_rows = update_frag.xpath('.//table[contains(@class, "rgMasterTable")]/tbody/tr')
    table_rows.each do |table_row|
      table_cols = table_row.xpath('./td')
      row_data = table_cols.map(&:text)
      member_list << row_data
    end
    [member_list, update_frag]
  end

  def extract_form_fields(response)
    fname_box_name, lname_box_name = nil
    parsed_doc = Nokogiri::HTML.parse(response.body)
    field_elements = parsed_doc.xpath(
      '//form[@id="aspnetForm"]//input[@name][not(contains(@type, "button"))][not(contains(@type, "submit"))]'
    )

    form_fields = {}

    field_elements.each do |field_el|
      form_fields[field_el[:name]] = field_el[:value] || ''
    end

    server_id_regex = /Sys\.Application\.setServerId\s*\(\s*['"][^'"]*['"]\s*,\s*['"]([^'"]*)['"]\s*\)/i
    server_id_matches = server_id_regex.match(response.body)
    server_id = server_id_matches[1] unless server_id_matches.nil? || server_id_matches.length != 2

    lister_panel_els = parsed_doc.xpath('//div[contains(@id, "_ListerPanel")]')
    lister_panel_el = lister_panel_els[0] if lister_panel_els.count.positive?
    lister_panel_name = lister_panel_el[:id].gsub('_', '$') unless lister_panel_el.nil?

    submit_button_els = parsed_doc.xpath('//input[@type="submit"][contains(@id, "_SubmitButton")]')
    submit_button_el = submit_button_els[0] if submit_button_els.count.positive?
    submit_button_name = submit_button_el[:name] unless submit_button_el.nil?

    filter_label_els =
      parsed_doc.xpath(
        '//div[contains(@class, "FilterPanel")]//div[contains(@class, "PanelField")]//label'
      )
    filter_label_els.each do |filter_label_el|
      if filter_label_el.text.downcase.include?('first name')
        fname_box_name = filter_label_el[:for]&.gsub('_', '$')
      elsif filter_label_el.text.downcase.include?('last name')
        lname_box_name = filter_label_el[:for]&.gsub('_', '$')
      end
    end

    if server_id.nil? ||
       lister_panel_name.nil? ||
       submit_button_name.nil? ||
       fname_box_name.nil? ||
       lname_box_name.nil?
      raise(
        <<~MESSAGE.gsub(/\r|\n|\r\n/, ' ').squeeze(' ')
          Could not extract the key elements:
          server_id=#{server_id},
          lister_panel=#{lister_panel_name},
          submit_button=#{submit_button_name},
          first_name_box=#{fname_box_name},
          last_name_box=#{lname_box_name}
        MESSAGE
      )
    end
    [form_fields, server_id, lister_panel_name, submit_button_name, fname_box_name, lname_box_name]
  end

  def parse_form_response(response)
    parsed_data = []
    data_str = response || ''

    while data_str.length.positive?
      # Length
      splitter_idx = data_str.index('|')
      return parsed_data if splitter_idx.nil?

      length_str = data_str[0, splitter_idx]
      length = length_str.to_i
      splitter_idx += 1
      data_str = data_str[splitter_idx..] || ''

      # Type
      splitter_idx = data_str.index('|')
      return parsed_data if splitter_idx.nil?

      type_str = data_str[0, splitter_idx]
      splitter_idx += 1
      data_str = data_str[splitter_idx..] || ''

      # Name
      splitter_idx = data_str.index('|')
      return parsed_data if splitter_idx.nil?

      name_str = data_str[0, splitter_idx]
      splitter_idx += 1
      data_str = data_str[splitter_idx..] || ''

      # Value
      value_str = data_str[0, length]
      splitter_idx = length + 1
      data_str = data_str[splitter_idx..] || ''

      parsed_data << [length, type_str, name_str, value_str]
    end

    parsed_data
  end  
  
  def set_page_count_from_response(response, page_count)
    return page_count unless page_count.nil?

    match_data = /\\?"PageCount\\?":\s*(\d+)[^\d]*/.match(response)
    return page_count unless !match_data.nil? && match_data.length == 2

    match_data[1].to_i
  end

  def update_form_fields_from_response(response, form_fields)
    response.select { |rd| rd[1] == 'hiddenField' }.each do |rd|
      form_fields[rd[2]] = rd[3]
    end
    form_fields
  end

  def update_form_fields_from_fragment(frag, form_fields)
    updated_form_fields = {}
    field_els = frag.xpath(
      './/input[@name][not(contains(@type, "button"))][not(contains(@type, "submit"))]'
    )

    field_els.each do |field_el|
      form_fields[field_el[:name]] = field_el[:value] || ''
    end
    updated_form_fields[:form_fields] = form_fields

    return updated_form_fields unless @go_page_box_name.nil? || @go_page_btn_name.nil?

    adv_part_xpath = <<~STRING.gsub(/\r|\n|\r\n/, '').squeeze(' ')
      .//table[contains(@class, "rgMasterTable")]
      /thead
      //td[contains(@class, "rgPagerCell")]
      /div[contains(@class, "rgAdvPart")]
    STRING
    adv_part_el = frag.xpath(adv_part_xpath)[0]
    return updated_form_fields if adv_part_el.nil?

    go_page_box_el = adv_part_el.xpath('.//input[contains(@name, "GoToPageTextBox")]')[0]
    return updated_form_fields if go_page_box_el.nil?

    go_page_state_el = adv_part_el.xpath('.//input[contains(@name, "GoToPageTextBox_ClientState")]')[0]
    return updated_form_fields if go_page_state_el.nil?

    go_page_btn_el = adv_part_el.xpath('.//input[contains(@name, "GoToPageLinkButton")]')[0]
    return updated_form_fields if go_page_btn_el.nil?

    updated_form_fields[:go_page_box_name] = go_page_box_el[:name]
    updated_form_fields[:go_page_btn_name] = go_page_btn_el[:name]
    updated_form_fields[:go_page_btn_text] = go_page_btn_el[:value]
    updated_form_fields[:go_page_state_name] = go_page_state_el[:name]
    updated_form_fields
  end

  private

  def tags_to_hash(field_tags)
    member_fields = {}
    tag_data = field_tags.css('span').each_slice(2).to_a
    member_fields[:name] = get_value(tag_data[0])
    member_fields[:bar_number] = get_value(tag_data[1])
    member_fields[:registration_status] = get_value(tag_data[2])
    member_fields[:law_firm_name] = get_value(tag_data[3])
    address = tag_data[4][1].children.select{|addr| !addr.text.empty?}
    if address.count == 5
      member_fields[:law_firm_address] = [address[0].text, address[1].text, address[2].text].join(' ').gsub("\n", "")
      match_data = /([^,]+),\s*([A-Z]{2})\s*([\d]{5})/.match(address[3].to_s.gsub("\n", ""))
    elsif address.count == 4
      member_fields[:law_firm_address] = [address[0].text, address[1].text].join(' ').gsub("\n", "")
      match_data = /([^,]+),\s*([A-Z]{2})\s*([\d]{5})/.match(address[2].to_s.gsub("\n", ""))
    else
      member_fields[:law_firm_address] = address[0].to_s
      match_data = /([^,]+),\s*([A-Z]{2})\s*([\d]{5})/.match(address[1].to_s.gsub("\n", ""))
    end
    
    # address[2].to_s is Berkeley, CA  94707
    if match_data
      member_fields[:law_firm_zip] = match_data[3]
      member_fields[:law_firm_city] = match_data[1]
      member_fields[:law_firm_state] = match_data[2]
      member_fields[:law_firm_county] = address.last.to_s.gsub("\n", "")
    end
    member_fields[:phone] = get_value(tag_data[6])
    member_fields[:fax] = get_value(tag_data[7])
    member_fields[:email] = get_email(field_tags[8])
    member_fields[:university] = get_value(tag_data[9])
    member_fields[:date_admited] = Date.strptime(get_value(tag_data[11]), '%m/%d/%Y').to_s if get_value(tag_data[11])
    member_fields[:md5_hash] = create_md5_hash(member_fields)
    member_fields
  end

  def get_email(tag)
    email_code = tag.at_xpath(".//div//span//a/@data-cfemail")&.value
    return unless email_code

    ncode_array = email_code.scan(/.{2}/)
    n_key = ncode_array.shift.to_i(16)
    ncode_array.map{|str| (str.to_i(16) ^ n_key).chr}.join
  end

  def get_value(tag_data)
    tag_data[1].text.empty? ? nil : tag_data[1].text
  end

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end
end
