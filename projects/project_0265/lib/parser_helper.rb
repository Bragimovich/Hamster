module ParserHelper

  def get_committee_data(data, committee_type, search_text)
    values = nil
    if committee_type == "housing"
      values = data.css("td").select { |e| e.text.include?(search_text) }
      return_val = values[0].children[1].text.strip
      return_val = return_val == "" ? nil : return_val
    elsif committee_type == "senate"
      values = data.css("strong").select { |e| e.text.include?(search_text) }
      return nil if values.empty?

      return_val = values.first.next_sibling&.text&.squish
    end
    return_val unless return_val&.empty?
  end

  def row_data(row, id, link)
    if (get_data(row, "Chair") != nil) && (!row.text.squish.include? "Vice Chair")
      title = "Chair"
      full_name = get_data(row, "Chair").first.next_element.css('text()')[-1].text.squish
    elsif  get_data(row, "Vice Chair") != nil
      title = "Vice Chair"
      full_name = get_data(row, "Vice Chair").first.next_element.css('text()')[-1].text.squish
    else
      title = "Members"
      begin
        full_name = get_data(row, "Members").first.next_element.css('text()')[-1].text.squish
      rescue Exception => e
        full_name = row.text.squish
      end
      full_name = full_name.include?(":") ? nil : full_name
    end
    [title, full_name]
  end

  def get_data(data, search_text)
    values = data.css("td").select{|e| e.text.include? search_text}
    values = values.count == 0 ? nil : values
    values
  end

  def name_spliting(full_name)
    return [nil, nil, nil] if full_name.nil?
    name_split = full_name.gsub("Rep." , "").squish.split(" ")
    first_name = name_split[0]
    middle_name = name_split.count > 2 ? name_split[1] : nil
    last_name = name_split[-1]
    [first_name, middle_name, last_name]
  end

  def get_data_bills(data, search_text)
    if data.css("##{search_text}").count==0
      return nil
    else
      if search_text == "cellSubjects"
        data = data.css("##{search_text}").children.map(&:text).reject(&:empty?).join(" ,")
      else
        data = data.css("##{search_text}").text.squish
      end
    end
    data
  end

  def get_senate_bill(data, search_text)
    link ,val= nil, nil
    table_number = 1
    if search_text == "Senate Committee"
      table = data.css("#tblComm1Committee")
      if table.text.include? search_text
        val = search_data(table, search_text)
      else
        table = data.css("#tblComm2Committee")
        val = search_data(table, search_text)
        table_number = 2
      end
      link = "https://capitol.texas.gov" + table.css("a")[0]['href'][2..-1] unless val.nil?
    end
    [val, link, table_number]
  end

  def get_house_bill(data, search_text)
    link ,val= nil, nil
    table_number = 2
    if search_text == "House Committee"
      table = data.css("#tblComm2Committee")
      if table.text.include? search_text
        val = search_data(table, search_text)
      else
        table = data.css("#tblComm1Committee")
        val = search_data(table, search_text)
        table_number = 1
      end
      link = "https://capitol.texas.gov" + table.css("a")[0]['href'][2..-1] unless val.nil?
    end
    [val, link, table_number]
  end

  def search_data(data, search_text)
    values = data.css("td").select{|e| e.text.include? search_text}
    val = values.count > 0 ? values[0].next_sibling.text.strip : nil
    val
  end
  
  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def get_legislature_session(legislature)
    "#{legislature.split("_").first[0..1]}(#{legislature.split("_").first[-1]})"
  end

  def create_link(legislature, bill)
    legislature = legislature.gsub("(",'').gsub(")",'').strip
    bill = bill.split(' ').join('')
    "https://capitol.texas.gov/BillLookup/History.aspx?LegSess=#{legislature}&Bill=#{bill}"
  end

  def get_common(hash, run_id)
    data_hash = {}
    data_hash["md5_hash"]       = create_md5_hash(hash)
    data_hash["run_id"]         = run_id
    data_hash["touched_run_id"] = run_id
    data_hash
  end

  def get_vote(data, key)
    data_hash = {}
    data_hash["#{key}_yes_votes"] = get_vote_value(data, "Ayes")
    data_hash["#{key}_no_votes"] =  get_vote_value(data, "Nays")
    data_hash["#{key}_present_not_voting"] = !data.nil? ? data[data.index("Present")..data.index("Present")+21].split("=")[-1].to_i : 0
    data_hash["#{key}_absent"] = !data.nil? ? data[data.index("Absent")..-1].split("=")[-1].to_i : 0
    data_hash
  end

  def get_vote_value(data, index_key)
    !data.nil? ? data[data.index(index_key)..data.index(index_key)+6].split("=")[-1].to_i : 0
  end

  def get_bill_commitee_data(data, comittee, table_number)
    if comittee.nil?
      status = nil
      votes =  nil
    else
      status = get_data_bills(data,"cellComm#{table_number}CommitteeStatus")
      votes =  get_data_bills(data,"cellComm#{table_number}CommitteeVote")
    end
    [status, votes]
  end

  def get_effective_date(data)
    if data.css("#cellLastAction").text.include? ":"
      get_index = data.css("#cellLastAction").text.index(":")
      get_date = data.css("#cellLastAction").text[get_index+1..-1].strip
      get_date = get_date.to_date rescue nil
    elsif  data.css("#cellLastAction").text.include? "Effective on"
      get_index = data.css("#cellLastAction").text.index("on")
      get_date = data.css("#cellLastAction").text[get_index+2..-1].strip
      unless get_date.include?". . . "
        get_date = Date.strptime(get_date, "%m/%d/%y") rescue nil
      end
    else
      get_date = nil
    end
    get_date
  end

end
