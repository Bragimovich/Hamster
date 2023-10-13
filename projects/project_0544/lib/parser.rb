class Parser < Hamster::Parser
  def main_page(request)
    Nokogiri::HTML(request.force_encoding("utf-8"))
  end

  def pdf_links(main_page_doc)
    main_page_doc.css(".padding a")[3..-1].map{|a| a["href"]}
  end

  def fetch_action_url(page)
    page.css("#searchForm").first["action"]
  end

  def get_info(file_path, link)
    reader = PDF::Reader.new(open(file_path))
    @document  = reader.pages.first.text.scan(/^.+/)
    reader.pages.each_with_index do |page, index|
      next if index == 0
      @document = @document + page.text.scan(/^.+/)
    end
    data_lines = []
    @document.each do |line|
      data_lines.append(line.strip)
    end
    data_lines
  end

  def party_info(data_lines, link, run_id, court_id, page, s3)
    data_array_info = []
    data_array_add_info = []
    data_array_party = []
    data_array_aws = []
    data_array_relations = []
    indexes = index(data_lines)
    check_value = data_lines.select{|a| (a.include? "No.") || (a.include? "No(s)") || (a.include? "Nos")}[0].split.first
    line_no = get_line(data_lines,check_value)
    indexes.each_with_index do |index, ind|
      data_hash = {}
      data_hash[:court_id] = court_id
      case_id = get_values(data_lines,0, ind, link)
      case_id = data_array_info[0][:case_id] if case_id.nil?
      case_id = clean_name(case_id, ",")
      data_hash[:case_id] = case_id
      data_hash[:case_name] = case_name(data_lines, index, link)
      data_hash[:case_filed_date] = file_date(data_lines, line_no)
      data_hash[:status_as_of_date] = "Opinion Filed"
      lower_case_id = get_values(data_lines,1, ind, link)
      lower_case_id = clean_name(lower_case_id, ",") unless lower_case_id.nil?
      data_hash[:lower_case_id] = (lower_case_id.nil?)? data_array[0][:lower_case_id] : lower_case_id rescue nil
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:data_source_url] = link
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_array_info << data_hash
      value = additional_info(data_lines, data_hash)
      data_array_add_info << value unless  ((value.nil?) || (value.empty?))
      data_array_party << is_lawyer_0(data_lines, data_hash, index)
      data_array_party << is_lawyer_1(data_lines, data_hash, data_array_party.flatten)
      data_array_aws << get_aws_uploads(page, data_hash, s3)
      data_array_relations << get_relations_pdf(court_id, data_hash[:md5_hash], data_array_aws[ind][:md5_hash] , run_id)
    end
    [data_array_info, data_array_add_info, data_array_party.flatten, data_array_aws, data_array_relations]
  end

  def case_activities(court_id, pp, run_id, link)
    data_array = []
    total_rows = pp.css("#resultsTable tbody").css("tr")
    total_rows.each do |row|
      data_hash = {}
      data_hash[:court_id] = court_id
      data_hash[:case_id] = pp.css("strong").select{|a| a.text == "Case:"}[0].next_sibling.text.split("-").first.squish
      data_hash[:activity_date] = row.css("td")[0].text
      data_hash[:activity_desc] = get_activity_desc(row)
      data_hash[:activity_type] = row.css("td")[1].text
      data_hash[:file] = link
      data_hash[:data_source_url] = "https://apps.utcourts.gov/CourtsPublicWEB/LoginServlet"
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_array << data_hash
    end
    data_array
  end

  private

  def additional_info(data_lines, data)
    data_hash = {}
    value = data[:lower_case_id]
    return if value.nil? 
    line_no = get_line(data_lines,"Honorable")
    check_line = get_line(data_lines,"Heard")
    data_hash[:court_id] = data[:court_id]
    data_hash[:case_id] = data[:case_id]
    data_hash[:lower_court_name] = data_lines[line_no-1] rescue nil
    data_hash[:lower_case_id] = data[:lower_case_id]
    data_hash[:lower_judge_name] = data_lines[line_no] rescue nil
    data_hash[:lower_judgement_date] = data_lines[check_line].split("Heard").last.squish rescue nil
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:data_source_url] = data[:data_source_url]
    data_hash[:run_id] = data[:run_id]
    data_hash[:touched_run_id] = data[:run_id]
    data_hash
  end

  def get_relations_pdf(court_id, case_info_md5, aws_pdf_md5, run_id)
    {
      court_id: court_id,
      run_id: run_id,
      case_info_md5: case_info_md5,
      case_pdf_on_aws_md5: aws_pdf_md5
    }
  end

  def file_date(data_lines, line_no)
    if data_lines[line_no+1].include? "Filed"
      return data_lines[line_no+1].split[1..-1].join(" ")
    elsif data_lines[line_no+2].include? "Filed"
      return data_lines[line_no+2].split[1..-1].join(" ")
    else
      return data_lines[line_no+1]
    end
  end

  def get_activity_desc(row)
    data = row.css("td")[1].text
    data = data + " Disposition code: " + row.css("td")[2].text unless (row.css("td")[2].text.empty?)
    data = data + " Disposition date: " + row.css("td")[3].text unless (row.css("td")[3].text.empty?)
    data
  end

  def index(data_lines)
    indexes = []
    data_lines.each_with_index do |e , ind|
      if  e == ("v.")
        indexes.append(ind)
      end
    end
    check_box = data_lines.select{|a| (a.include? "No.") || (a.include? "No(s)") || (a.include? "Nos")}[0]
    indexes.append(indexes[0]) if (((check_box.include? ",") || (check_box.include? "and")) and (indexes.size == 1))
    indexes
  end

  def get_aws_uploads(page, data, s3)
    data_hash = {}
    data_hash[:court_id] = data[:court_id]
    data_hash[:case_id] = data[:case_id]
    link = data[:data_source_url].split("/").last.gsub("%20","")
    key = "us_courts/345/#{data[:case_id]}/#{link}"
    data_hash[:aws_link] = upload_on_aws(s3, page, key)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:source_link] = data[:data_source_url]
    data_hash[:data_source_url] = data[:data_source_url]
    data_hash[:run_id] = data[:run_id]
    data_hash[:touched_run_id] = data[:run_id]
    data_hash
  end

  def upload_on_aws(s3, file, key)
    url = 'https://court-cases-activities.s3.amazonaws.com/'
    return "#{url}#{key}" unless s3.find_files_in_s3(key).empty?
    s3.put_file(file, key, metadata={})
  end

  def case_name(data_lines, index,link)
    line = index_case_name(data_lines, index, 0)
    fname = ""
    (line...index-1).each do |counter|
      fname = fname + " " + data_lines[counter]
    end
    line = index_case_name(data_lines, index, 1)
    lname = ""
    (index+1...line).each do |counter|
      lname = lname + " " + data_lines[counter]
    end
    clean_name(fname, ",").squish + (" v. ") + clean_name(lname, ",").squish
  end

  def index_case_name(data_lines, index, case_split)
    line = 0
    (0..8).each do |counter|
      name = case_split == 0 ? data_lines[index-2-counter] : data_lines[index+1+counter]
      if (check_for_court(name) || check_for_attorney(name) || check_for_other(name))
        line = case_split == 0 ? index-1-counter : index + counter + 1
        break
      end
    end
    line
  end

  def is_lawyer_0(data_lines, data, index)
    data_array = []
    (0..1).each do |ind|
      line = (ind==0)? (index-1) : (index_case_name(data_lines, index, 1))
      cases = data[:case_name].split("v.")[ind]
      cases = cases.split(",")
      cases.each do |case_index|
        case_index = clean_name(case_index.squish, ".")
        if case_index.size < 6
          next if invalid_party(case_index)
        end
        data_hash = {}
        data_hash[:court_id] = data[:court_id]
        data_hash[:case_id] = data[:case_id]
        data_hash[:is_lawyer] = 0
        data_hash[:party_name] = case_index.squish
        party_type = clean_name(data_lines[line].squish, ".")
        party_type = clean_name(party_type.squish, ",")
        data_hash[:party_type] = party_type
        data_hash[:party_description] = nil
        data_hash[:md5_hash] = create_md5_hash(data_hash)
        data_hash[:data_source_url] = data[:data_source_url]
        data_hash[:run_id] = data[:run_id]
        data_hash[:touched_run_id] = data[:run_id]
        data_array << data_hash
      end
    end
    data_array.flatten
  end

  def is_lawyer_1(data_lines, data, data_party)
    str_index = get_line(data_lines, "Attorneys:")
    if (str_index.nil?)
      str_index = get_line(data_lines, data[:lower_case_id])
    end
    str_index = str_index + 1
    case_name = data_lines[str_index..str_index+40].select{|a| a.match?(/CHIEF|PER|JSTICEP|HIEF|PERC|JUSTICE|USTICE|Other|consolidated|this Memorandum/)}
    case_name = data_lines.select{|a| a.split.first.match?(/JUDGE|JDGE|UDGE/)} if (case_name.nil? || case_name.empty?)
    end_index = data_lines.index case_name[0]
    party_desc = data_lines[str_index...end_index].join(" ")
    data_array = []
    lines_party = []
    str = ""
    flag = -1
    (str_index...end_index).each_with_index do |row, index|
      str.concat("#{data_lines[row]} ")
      next if flag == index
      if ((data_lines[row].include? "for"))
        unless (check_for_attorney(data_lines[row]))
          str.concat("#{data_lines[row+1]} ")
          flag = index + 1
        end
        lines_party << str
        str = ""
      end
    end
    lines_party.each do |line|
      final_data = party_info_law(line, data, data_party, party_desc)
      data_array <<  final_data unless final_data.nil?
    end
    data_array.flatten
  end

  def party_info_law(case_row, data, data_party, party_desc)
    data_array = []
    array = (data_party[0][:court_id].to_i == 480)? case_row.split("for") : case_row.split(", for") rescue nil
    return nil if array.nil?
    party_type = array.last.squish
    final_array = array[0..-2].join.split(",")
    final_array.each do |row|
      data_hash = {}
      next if ((row.match?(/City|Asst.|Att’y|Att�y|Solic.|City|Heights|Gen.|for|__|Attorney/)) || (row.squish.size <= 3))
      data_hash[:court_id] = data[:court_id]
      data_hash[:case_id] = data[:case_id]
      data_hash[:is_lawyer] = 1
      data_hash[:party_name] = row.squish
      data_hash[:party_type] = make_party_type(party_type, data_party, row.squish, data, case_row)
      data_hash[:party_description] = party_desc
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:data_source_url] = data[:data_source_url]
      data_hash[:run_id] = data[:run_id]
      data_hash[:touched_run_id] = data[:run_id]
      data_array << data_hash
    end
    data_array
  end

  def make_party_type(party_type, data_party, party_name, data, case_row)
    return nil if ((party_type.nil?) || (party_type.empty?))
    if (party_type.include? "and")
      party_type = ((party_type.split[1].include? "and") || (party_type.split[2].include? "and")) ? party_type : party_type.split.first
    else
      party_type = party_type.split.first
    end
    unless check_for_attorney(party_type)
      party_temp = data_party.each.select{|a| a[:party_name].include? party_type}.map{|a| a[:party_type]}[0]
      party_type = party_temp unless party_temp.nil?
    end
    party_type = clean_name(party_type.squish, ",")
    party_type = clean_name(party_type.squish, ".")
    party_type
  end

  def check_for_court(name)
    name = name.gsub(" ","").upcase
    name.match?(/SUPREMECOURTOFTHESTATEOFUTAH|THEUTAHCOURTOFAPPEALS|COUNTIES,INUTAH|UNDEREIGHTEENYEARS/)
  end

  def check_for_attorney(value)
    value = value.downcase
    value.match?(/appell|petitioner|respondent|defendant|cross|plantiff|amicus|amici/)
  end

  def check_for_other(name)
    name = name.split[0..1].join.downcase
    name.match?(/__|inre|inthe/)
  end

  def invalid_party(case_index)
    case_index = case_index.gsub(" ","").downcase
    case_index.match?(/llc|etal|inc|llp|nc|jr|ltd|l.c/)
  end

  def get_line(data_lines, value)
    case_number = data_lines.select{|a| a.include? "#{value}"}[0]
    data_lines.index case_number
  end

  def get_values(data_lines,ind, value, link)
    case_id = data_lines.select{|a| a.match?(/No.|No(s)|Nos/)}[ind].split[1..-1] rescue nil
    return nil if case_id.nil? || case_id.empty?
    case_id = value > 0 ? case_id.last : case_id.first
    case_id = (case_id[/\d/].nil?)?  nil : case_id
    if ind > 0
      line_no = get_line(data_lines, case_id)
      case_id = (data_lines[line_no-1].include? "Honorable") ? case_id : nil
    end
    case_id
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def clean_name(value, check)
    (value.last == "#{check}")? value[..-2] : value
  end
end
