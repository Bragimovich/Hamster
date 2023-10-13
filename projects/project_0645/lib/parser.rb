# frozen_string_literal" => true
class Parser < Hamster::Parser
  def parse_html(request)
    Nokogiri::HTML(request.force_encoding('utf-8'))
  end

  def get_main_body(page)
    vs  = page.css('input')[3]['value']
    ev = page.css('input')[6]['value']
    vsg = page.css('input')[4]['value']
    [vs, ev, vsg]
  end

  def get_links(main_page)
    list = main_page.css('#itemPlaceholderContainer th').map { |e| e.text.squish }
    index = list.index "Case"
    array = main_page.css("#itemPlaceholderContainer tr[valign = 'top']").reject{|a| a.text.include? "Events"}
    links_array = array.map{|a| a.css("td")[index].css("a[href]")[0].attributes["href"].text.split("'")[1]}
    case_id_array = array.map{|a| a.css("td")[index].css("a[href]")[0].children.text}
    [links_array, case_id_array]
  end

  def next_link(main_page)
    main_page.css("a").select{|a| a.text.include? "Next"}[0]["href"].split("'")[1] rescue nil
  end

  def get_info(info_page, run_id)
    info_array = []
    result = get_td_result(info_page)
    return nil if result.nil?
    data_hash = {}
    data_hash[:case_id] = result[8].text.empty? ? result[1].text : "#{result[8].text}_#{result[1].text}"
    data_hash[:case_name] = result[5].text.squish
    data_hash[:case_filed_date] = DateTime.strptime(result[2].text, "%m/%d/%Y").to_date
    data_hash[:case_type] = result[3].text
    data_hash[:case_description] = result[4].text
    data_hash[:disposition_or_status] = nil
    data_hash[:status_as_of_date] = result[6].text
    data_hash[:judge_name] = result[7].text
    data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    info_array << data_hash
    info_array
  end

  def get_activities(info_page, run_id)
    data_array = []
    result = get_td_result(info_page)
    activity_result = info_page.css("#ctl00_ContentPlaceHolder1_gridViewEvents tr[align='center']").select{|a| a.parent.classes.count > 1}
    activity_result.each_with_index do |activity, index|
      inner_activity = activity.css(".Nested_ChildGrid").css("tr")
      inner_activity.each do |inner_act|
        data_hash = {}
        data_hash[:case_id] = result[8].text.empty? ? result[1].text : "#{result[8].text}_#{result[1].text}"
        data_hash[:activity_date] = DateTime.strptime(activity.css("td")[2].text.squish, "%m/%d/%Y").to_date
        data_hash[:activity_type] = activity.css("td")[3].text.squish
        data_hash[:activity_decs] = activity.css("td")[4].text.squish
        link = inner_act.css('a').select{|a| a.text.include? 'View'}[0]['href'] rescue nil
        data_hash = mark_empty_as_nil(data_hash) unless data_hash.nil?
        data_hash[:md5_hash] = create_md5_hash(data_hash)
        data_hash[:activity_pdf]  = link.nil? ? nil : "https://www.cclerk.hctx.net/applications/websearch/#{link}"
        data_hash[:run_id] = run_id
        data_hash[:touched_run_id] = run_id
        data_array << data_hash
      end
    end
    data_array
  end

  def get_party(info_page, run_id)
    party_array = []
    result = get_td_result(info_page)
    party_result = get_party_result(info_page)
    return nil if party_result.nil?
    party_result.each do |party|
      data = get_text_element(party, 2, 0)
      data_count = data.count
      party_hash = {}
      party_hash[:case_id] = result[8].text.empty? ? result[1].text : "#{result[8].text}_#{result[1].text}"
      party_hash[:is_lawyer] = 0
      party_hash[:party_name] = data[0].text.squish
      next if party_hash[:party_name].nil?
      party_hash[:party_type] = party.css("td")[1].text
      party_hash[:law_firm] = nil
      party_hash[:party_address] = data[1..-1].map{|e| e.text}.join("\n")
      party_hash[:party_city], party_hash[:party_state], party_hash[:party_zip] = data_count > 1 ? city_state_zip(data[-1].text.squish) : nil
      party_hash[:party_description] = data_count > 1 ? party_description(data) : nil
      party_hash = mark_empty_as_nil(party_hash) unless party_hash.nil?
      party_hash[:md5_hash] = create_md5_hash(party_hash)
      party_hash[:run_id] = run_id
      party_hash[:touched_run_id] = run_id
      party_array << party_hash unless party_hash.empty?
    end
    get_lawyer_1(party_array, run_id, info_page)
    party_array
  end

  private

  def get_lawyer_1(party_array, run_id, info_page)
    party_result = get_party_result(info_page)
    return nil if party_result.nil?
    party_result.each do |party|
      data = get_text_element(party, 3, 0)
      index = data.find_index(data.select{|a| a.text.include? "Phone"}[0]) rescue nil
      size = data.count
      party_hash = {}
      party_hash[:case_id] = party_array[0][:case_id]
      party_hash[:is_lawyer] = 1
      check_data = data.empty? ? get_text_element(party, 3, 1)[0] : data[0]
      party_hash[:party_name] = check_data.text.squish rescue nil
      next if party_hash[:party_name].nil?
      party_hash[:party_type] = party.css("td")[1].text
      party_hash[:law_firm] = ((size >= 6) && (data[1].text.squish.scan(/[0-9]/).empty?))? data[1].text.squish : nil
      party_hash[:party_address] = party_hash[:law_firm].nil? ? party_address(data, 1) : party_address(data, 2)
      party_hash[:party_city], party_hash[:party_state], party_hash[:party_zip] = city_state_zip(data[index-1].text.squish) rescue nil
      party_hash[:party_description] = party_description(data)
      party_hash = mark_empty_as_nil(party_hash) unless party_hash.nil?
      party_hash[:md5_hash] = create_md5_hash(party_hash)
      party_hash[:run_id] = run_id
      party_hash[:touched_run_id] = run_id
      party_array << party_hash unless party_hash.empty?
    end
    party_array
  end

  def city_state_zip(data)
    data = data.split
    data_count = data.count
    city, state, zip = nil, nil, nil
    if data_count == 3
      city = data[0]
      state = data[1]
      zip = data[2]
    elsif data_count == 4
      if (data[3].scan(/[a-z]/) || data[3].scan(/#/))
        return [city,state,zip]
      else
        city = data[0..1].join(" ")
        state = data[2]
        zip = data[3]
      end
    elsif data_count == 2
      city = data[0]
      state = nil
      zip = data[1]
    end
    [city,state,zip]
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

  def get_td_result(info_page)
    info_page.css("tr[align='center']")[0].css("td") rescue nil
  end

  def get_party_result(info_page)
    info_page.css(".table")[1].css("tr")[1..-1] rescue nil
  end

  def get_text_element(party, start_index, end_index)
    party.css("td")[start_index].css("span")[end_index].css('text()')
  end

  def party_address(data, str_index)
    data[str_index..index-1].map{|e| e.text}.join("\n") rescue nil
  end

  def party_description(data)
    data[0..-1].map{|e| e.text.gsub(/(&nbsp;|\s)+/, " ")}.join("\n") rescue nil
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
