class Parser < Hamster::Parser

  def parse_html(page)
    Nokogiri::HTML(page.force_encoding("utf-8"))
  end

  def pdf_parsing(pdf_file)
    reader = PDF::Reader.new(pdf_file)
    @document  = reader.pages.first.text.scan(/^.+/)
    reader.pages.each_with_index do |page, index|
      next if index == 0
      @document = @document + page.text.scan(/^.+/)
    end
    @document
  end

  def get_request_verificatio_token(main_page_parsing)
    main_page_parsing.xpath('//input[@name="__RequestVerificationToken"]').map {|e| e['value']}
  end

  def pdf_links(main_page_request)
    links = main_page_request.css(".table td div a").map{|a|a["href"]}.select{|a| a.include? "DocketSheet"}
    data  = main_page_request.css(".table tr")[1..-1].map{ |a| a.css("td")}
    [links, data]
  end

  def case_data(page, run_id, link, row) 
    case_info = {}
    case_info[:case_name]                                    = case_name(page)
    case_info[:case_type]                                    = nil
    case_info[:case_id]                                      = row.children[2].text
    case_info[:case_filed_date]                              = DateTime.strptime(row.children[6].text, "%m/%d/%Y").to_date rescue nil
    case_info[:status_as_of_date]                            = row.children[5].text
    case_info[:disposition_or_status]                        = get_value_final(page, "Disposition:")
    case_info[:case_description]                             = make_description(page, "CASE INFORMATION")
    case_info[:judge_name]                                   = get_value_final(page, "Judge Assigned:")
    case_info                                                = mark_empty_as_nil(case_info) unless case_info.nil?
    case_info.update(make_columns(case_info, link, run_id))
    case_judgement                                           = get_judgement(page, run_id, link, case_info) unless (case_info[:judge_name].nil?)
    [case_info, case_judgement]
  end

  def get_lawyer(page, run_id, link, file_name)
    party_array = []
    flag = false
    str_index, end_index = get_index(page, "CASE PARTICIPANTS")
    count = page[str_index+1].split("  ").select{ |a| !a.empty?}.count
    (str_index+1...end_index).each do |index|
      next if page[index].match?(/Participant Type|Participant Name|Address/)
      index_count = page[index].split("  ").select{ |a| !a.empty?}.count
      next if ((index_count == 1) && (page[index].split("  ").count > 4))
      case_party = {}
      case_party[:case_id]                                  = page.select{ |a| a.include? "Docket Number"}[0].split("Docket Number:").last.squish
      case_party[:is_lawyer]                                = 0
      case_party[:party_name]                               = get_name(page, index, count, index_count)
      case_party[:party_type]                               = page[index].split("  ").select{ |a| !a.empty? }[0].squish
      case_party[:law_firm]                                 = nil
      case_party[:party_address], case_party[:party_city], case_party[:party_state], case_party[:party_zip], case_party[:party_description] = make_party(page, index, case_party[:party_name], link, file_name)
      case_party.update(make_columns(case_party, link, run_id))
      party_array << case_party
    end
    party_array << get_lawyer_1(page, run_id, link, party_array)
    party_array.flatten.reject{ |a| a.empty?}
  end

  def get_activities(page, run_id, link, aws_data)
    activities_array = []
    activities_relation = []
    str_index, end_index = get_index(page, "DOCKET ENTRY INFORMATION")
    return "" if str_index.nil?
    (str_index+2...end_index).each do |count|
      next if page[count].split("  ").reject{ |a| a.empty?}.count == 1
      case_party = {}
      case_party[:case_id]                    = page.select{ |a| a.include? "Docket Number"}[0].split("Docket Number:").last.squish
      case_party[:activity_date]              = DateTime.strptime(page[count].split("  ").reject{ |a| a.empty?}[0].squish, "%m/%d/%Y").to_date rescue nil
      case_party[:activity_type]              = page[count].split("  ").reject{ |a| a.empty?}[1].squish
      case_party[:activity_decs]              = make_activity(page, count)
      case_party[:activity_pdf]               = link
      case_party[:file]                       = link
      case_party.update(make_columns(case_party, link, run_id))
      activities_relation << get_relations_activity_pdf(case_party[:md5_hash], aws_data[:md5_hash], run_id)
      activities_array << case_party
    end
    [activities_array, activities_relation]
  end

  def get_aws_uploads(page, run_id, link, row, s3)
    data_hash = {}
    data_hash[:case_id]                       = row.children[2].text
    key                                       = "us_courts/102/#{row.children[2].text}/info.pdf"
    data_hash[:source_link]                   = link
    data_hash[:aws_link]                      = upload_on_aws(s3, page, key)
    data_hash[:source_type]                   = "info"
    data_hash[:aws_html_link]                 = nil
    data_hash.update(make_columns(data_hash, link, run_id))
    data_hash
  end

  def upload_on_aws(s3, file, key)
    url = 'https://court-cases-activities.s3.amazonaws.com/'
    return "#{url}#{key}" unless s3.find_files_in_s3(key).empty?
    s3.put_file(file, key, metadata={})
  end

  def get_relations_pdf(case_info_md5, aws_pdf_md5, run_id)
    {
      run_id: run_id,
      case_info_md5: case_info_md5,
      case_pdf_on_aws_md5: aws_pdf_md5,
      touched_run_id: run_id
    }
  end

  private

  def get_relations_activity_pdf(activity_md5, aws_pdf_md5, run_id)
    {
      run_id: run_id,
      case_activities_md5: activity_md5,
      case_pdf_on_aws_md5: aws_pdf_md5,
      touched_run_id: run_id
    }
  end

  def make_columns(case_information, link, run_id)
    case_info = {}
    case_info[:md5_hash]             = create_md5_hash(case_information)
    case_info[:data_source_url]      = link
    case_info[:run_id]               = run_id
    case_info[:touched_run_id]       = run_id
    case_info
  end

  def make_activity(page, count)
    desc           = page[count].split("  ").reject{ |a| a.empty?}
    next_desc      = page[count+1].split("  ").reject{ |a| a.empty?}
    if (desc[2].nil?) && (page[count+1].split("  ").reject{ |a| a.empty?}.count==1)
      desc << page[count+1].split("  ").reject{ |a| a.empty?}[0]
      next_desc = page[count+2].split("  ").reject{ |a| a.empty?} if page[count+2].split("  ").reject{ |a| a.empty?}.count == 1
    end
    activity       = "Filer: ".concat(desc[2].squish) unless desc[2].nil?
    activity       = activity.concat("\n #{next_desc[0].squish}") if (next_desc.count == 1) rescue nil
    file           = "Applies to: ".concat(desc[3]) unless desc[3].nil?
    activity.concat("\n #{file}") rescue nil
  end

  def get_judgement(page, run_id, link, data_hash)
    case_judgement = {}
    case_judgement[:case_id]                      = data_hash[:case_id]
    case_judgement[:complaint_id]                 = get_value_final(page, "Complaint No")
    case_judgement[:party_name]                   = data_hash[:judge_name]
    fee_amount                                    = get_value_final(page, "Claim Amount:")
    case_judgement[:fee_amount]                   = fee_amount.nil? ? page[(page.index page.select{ |a| a.include? "Claim"}[0])-1].split.select{ |a| a.include? "$"}[0] : fee_amount rescue nil
    judgment_amount                               = get_value_final(page, "Judgement Amount:")
    case_judgement[:judgment_amount]              = judgment_amount.nil? ? get_value_final(page, "Judgment Amount:") : judgment_amount
    case_judgement[:judgment_date]                = data_hash[:case_filed_date]
    case_judgement.update(make_columns(case_judgement, link, run_id))
  end

  def get_lawyer_1(page, run_id, link, party_array_zero)
    party_array = []
    str_index, end_index = get_index(page, "ATTORNEY INFORMATION")
    return "" if str_index.nil?
    count                = page[str_index+1...end_index].join.squish.split.count("Name:")
    index_array          = get_index_option(page, str_index, end_index, "Name:")
    address_array        = get_index_option(page, str_index, end_index, "Address:")
    (0...count).each do |counter|
      case_party = {}
      case_party[:case_id]                 = page.select{ |a| a.include? "Docket Number"}[0].split("Docket Number:").last.squish
      name, type                           = get_name_lawyer(page, counter, party_array_zero, index_array, str_index, link)
      next if (name.nil? || name.empty?)
      case_party[:is_lawyer]               = 1
      case_party[:party_name]              = name
      case_party[:party_type]              = type
      law_firm, address, city, state, zip  = get_address_lawyer(page, counter, address_array, str_index, link)
      next if (address.nil? || address.empty?)
      case_party[:law_firm]                = law_firm
      case_party[:party_address]           = address
      case_party[:party_city]              = city
      case_party[:party_state]             = state
      case_party[:party_zip]               = zip
      case_party[:party_description]       = page[str_index+1...end_index].map{ |a| a.squish}.join("\n")
      case_party                           = mark_empty_as_nil(case_party) unless case_party.nil?
      case_party.update(make_columns(case_party, link, run_id))
      party_array << case_party
    end
    party_array
  end

  def get_address_lawyer(page, counter, address_array, str_index, link)
    counter == 1 if (page[str_index+address_array[0]].split("  ")[-4..-2].select{ |a| a.include? "Address"}.count > 0 && address_array.count == 1) rescue nil
    line_1 = line_seperator(page, counter, address_array, str_index, 1)
    line_2 = line_seperator(page, counter, address_array, str_index, 2)
    line_3 = line_seperator(page, counter, address_array, str_index, 3)
    return "" if line_1.nil?
    if ((line_1.match?(/,/)) && !(line_1.scan(/[0-9]/).empty?))
      line_3 = line_1
      line_1 = page[str_index+address_array[counter]].split(":").last.squish
      line_2 = ""
    end
    if line_2.nil?
      line_2 = line_seperator(page, counter, address_array, str_index, 3)
      line_3 = line_seperator(page, counter, address_array, str_index, 4)
    end
    if line_3.nil?
      line_3 = line_2
      line_2 = line_1
      line_1 = ""
    end
    return "" if ((line_3.nil?) || (line_2.nil?))
    if ((line_3.exclude? ",") && (line_2.exclude? ","))
      line_2 = line_3
      line_3 = line_seperator(page, counter, address_array, str_index, 4)
    end
    if ((line_2.match?(/,/)) && !(line_2.scan(/[0-9]/).empty?))
      line_3 = line_2
      line_2 = line_1
      line_1 = ""
    end
    address  = make_address_line(line_1, line_2, line_3).join("\n")
    city, state, zip = split_address(line_3, link)
    [line_1, address, city, state, zip]
  end

  def make_address_line(line_1, line_2, line_3)
    lines = []
    lines << line_1 unless line_1.empty?
    lines << line_2 unless line_2.empty?
    lines << line_3 unless line_3.empty? rescue nil
    lines
  end

  def line_seperator(page, counter, address_array, str_index, value)
    line = make_address(page, counter, address_array, str_index, value)[counter].squish rescue nil
    line = make_address(page, counter, address_array, str_index, value)[0].squish if line.nil? rescue nil
    line
  end

  def make_address(page, counter, address_array, str_index, value)
    page[str_index+address_array[counter]+value].lstrip.split("  ").reject{ |a| a.empty? || (a.include? ":")}
  end

  def get_index_option(page, str_index, end_index, option)
    option_array = []
    page[str_index..end_index].each_with_index do |line, index|
      if line.include? option
        counter = line.split.count(option)
        (0...counter).each do |counti|
          option_array << index
        end
      end
    end
    option_array
  end

  def get_name_lawyer(page, counter, party_array_zero, array, str_index, link)
    names = party_array_zero.map{ |a| a[:party_name]}
    if (page[(str_index+array[counter])].split.count("Name:") != 1)
      name, type = get_name_type(page, counter, str_index, counter, names, array, link, party_array_zero)
      else
      name, type = get_name_type(page, counter, str_index, 0, names, array, link, party_array_zero)
    end
    [name, type]
  end

  def get_name_type(page, counter, str_index, value, names, array, link, party_array_zero)
    name = get_name_index(page, counter, str_index, 0, "Name:", array)[value].squish  rescue nil
    name = (name.nil? || name.empty?) ?  get_name_index(page, counter, str_index, -1, "Name:", array)[value].squish : name rescue nil
    return "" if name.nil?
    type = get_name_index(page, counter, str_index, 1, "  ", array)[value].squish rescue nil
    if (((type.nil?) || (type.include? "Name:")) && (counter == 0) && (get_name_index(page, counter, str_index, 1, "  ", array).count == 1))
      type = get_name_index(page, counter, str_index, 2, "  ", array)[0].squish rescue nil
    else
      type = get_name_index(page, counter, str_index, 1, "  ", array)[0].squish rescue nil
    end
    type = make_party_type(type, page, counter, str_index, array)
    type = (names.include? name) ? party_array_zero.select{ |a| a[:party_name].include? name}.map{ |a| a[:party_type]}[0] : type
    type = (names.include? type) ? party_array_zero.select{ |a| a[:party_name].include? type}.map{ |a| a[:party_type]}[0] : type
    [name, type]
  end

  def get_name_index(page, counter, str_index, value, factor, array)
    page[str_index+array[counter]+value].split(factor).reject{ |a| a.empty? || (a.match(/\p{Lower}/).nil?)}
  end

  def make_party_type(type, page, counter, str_index, array)
    return "" if type.nil?
    if type.match?(/Representing:/)
      type = type.split("Representing:").reject{ |a| a.empty?}.first.squish
      type = get_name_index(page, counter, str_index, 2, "  ", array)[0].squish if ((get_name_index(page, counter, str_index, 2, "  ", array)).count == 1) || (get_name_index(page, counter, str_index, 2, "  ", array).select{ |a| a.include? "*"}.count > 0)
    elsif type.match?(/Office */)
      type = (counter == 0)? page[(str_index+array[counter])+2].split("  ").reject{ |a| (a.empty?) && (a.include? ":")}[counter].squish : page[(str_index+array[counter])+3].split("  ").reject{ |a| (a.empty?) && (a.include? ":")}[counter].squish
    elsif type.match?(/Name:/)
      type = page[(str_index+array[counter])+2].split("  ").reject{ |a| (a.empty?) && (a.include? ":")}[counter].squish
    end
    if type.match(/Supreme Court/)
      type = page[(str_index+array[counter])+2].split("  ").reject{ |a| (a.empty?) || (a.include? ":")}[0].squish
    end
    type
  end

  def get_value_final(page, option)
    value = page.select{ |a| a.include? option}[0].split("  ").reject{ |a| (a.empty?)} rescue nil
    index = value.index value.select{ |a| a.include? ":"}[1] rescue nil
    result = value[0...index].reject{ |a| a.include? ":"}[0].squish rescue nil
    if option == "Judge Assigned:" && result != nil
      index = (page.index page.select{ |a| (a.include? option)}[0]) + 1
      if page[index].split("  ").reject{ |a| a.empty?}.count == 1
        result = result.concat(" #{page[index].split(" ").reject{ |a| a.empty?}[0].squish}")
      end
    end
    result
  end

  def get_name(page, index, count, index_count)
    (count == index_count) ? page[index].split("  ").select{ |a| !a.empty? }[1].squish : page[index+1].split("  ").select{ |a| !a.empty? }[0].squish
  end

  def get_index(page, option)
    str_index = page.index page.select{ |a| (a.include? option)}[0]
    return nil if str_index.nil?
    index_array = []
    page.each_with_index do |line, index|
      if line.include? "Printed:"
        index_array << index
      end
    end
    end_index_1 = index_array.select{ |a| a > str_index}[0]
    end_index_2 = page.select{ |a| (a.match(/\p{Lower}/).nil?) && (a.scan(/[0-9]/).empty?)}.map{ |a| page.index a}.select{ |a| (a > str_index) && (a-str_index > 1)}[0]
    end_index_1 = 0 if end_index_1.nil?
    end_index_2 = 0 if end_index_2.nil?
    end_index = (end_index_1 > end_index_2) ? end_index_2 : end_index_1
    [str_index, end_index]
  end

  def make_party(page, index, name, link, file_name)
    if page[index].split("  ").select{ |a| !a.empty? }[2].nil?
      str_index, end_index = get_index(page, "DEFENDANT INFORMATION")
      return "" if str_index.nil?
      if page[str_index..end_index].to_s.include? "Name:"
        if page[str_index..end_index].to_s.include? name
          ind = (page[str_index..end_index].index page[str_index..end_index].select{ |a| a.include? "Address"}[0]) + str_index
          address = (ind+2 < end_index) ? page[ind+2].squish : page[ind+1].split("  ").last
          city, state, zip = split_address(address, link)
          description = make_description(page, 'DEFENDANT INFORMATION')
        end
      else
        address = get_address(page, "City/State/Zip:")
        return "" if address.nil?
        city, state, zip = split_address(address, link)
        description = make_description(page, 'DEFENDANT INFORMATION')
      end
    else
      address = page[index].split("  ").select{ |a| !a.empty? }[2]
      city, state, zip = split_address(address, link)
      description = nil
    end
    [address, city, state, zip, description]
  end

  def get_address(page, option)
    value = page.select{ |a| a.include? option}[0].split(":").reject{ |a| (a.empty?)} rescue nil
    index = value.index value.select{ |a| a.include? "City"}[0] rescue nil
    value[index+1].squish rescue nil
  end

  def split_address(address, link)
    return "" if (address.nil?) || (address.split.count < 2)
    city = address.split(",").first.squish
    state = address.split[1].squish
    zip = address.split.last.squish
    [city, state, zip]
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

  def make_description(page, option)
    str_index, end_index = get_index(page, option)
    description = page[str_index+1...end_index].map{ |a| a.split("  ")}.flatten.reject{ |a| a.empty?}.reject{ |a| a.split(":").count == 1}.join("\n")  rescue nil
    (description.nil? || description.empty?) ? page[str_index+1...end_index].map{ |a| a.squish}.join("\n") : description
  end

  def case_name(page)
    index = page.index page.select{ |a| a.include? "v."}[0]
    fname = (index.nil?) ? nil : (page[index-1].include? "Page") ? page[index-2] : page[index-1]
    lname = (index.nil?) ? nil : (page[index+1].include? "Page") ? page[index+2] : page[index+1]
    (index.nil?) ? page[(page.index page.select{ |a| a.include? "Page"}[0])-1].squish : "#{fname.squish} v. #{lname.squish}"
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
