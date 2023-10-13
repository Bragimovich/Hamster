# frozen_string_literal: true

class Parser < Hamster::Parser
  def parse_html(body)
    Nokogiri::HTML(body.force_encoding("utf-8"))
  end

  def get_body_data(parsed_page)
    view_state  = parsed_page.css("#__VIEWSTATE")[0]["value"]
    event_valid = parsed_page.css("#__EVENTVALIDATION")[0]["value"]
    view_generator =  parsed_page.css("#__VIEWSTATEGENERATOR")[0]["value"]
    [view_state, event_valid, view_generator]
  end

  def get_pages(pp, counter)
    pages = pp.css("#GridView1 tr").last.css("a").map{|e| e["href"].split(",")[-1].scan(/\d+/).join().to_i}
    next_flag = (pages.include? counter) ? false : true
    [pages, next_flag]
  end

  def get_links(pp)
    table  = pp.css("#GridView1")
    all_tr = table.css("tr")
    all_tr.shift
    all_links = all_tr.map{|tr| tr.css("a")[0]["href"]}
    all_links = all_links.reject{|link| link.include?"Page"}
    all_links.map{|link| link.split("$")[1].gsub("')", "")}
  end

  def get_file_name(response)
    pp = parse_html(response.body)
    pp.css("#lblSeqNo").text.strip
  end

  def get_suffix(name_spliting)
    suffix_value = nil
    if name_spliting.select{|s| s.upcase == "JR" || s.upcase == "JR." || s.upcase == "SR" || s.upcase == "SR."}.count > 0
      suffix_value = name_spliting.select{|s| s.upcase == "JR" || s.upcase == "JR." || s.upcase == "SR" || s.upcase == "SR."}[0]
    end
    suffix_value
  end
  
  def name_split(full_name)
    name_spliting = full_name.strip.split(' ')
    middle_name, last_name = nil, nil
    first_name  = name_spliting[0] rescue nil
    suffix_name = get_suffix(name_spliting)
    filtered_array = name_spliting.reject{|s| s.upcase == "JR" || s.upcase == "JR." || s.upcase == "SR" || s.upcase == "SR."}
  
    if filtered_array.count == 1
      middle_name = nil
      last_name = nil
    elsif filtered_array.count == 2
      middle_name = nil
      last_name = filtered_array[-1]
    elsif filtered_array.count == 3
      middle_name = filtered_array[1]
      last_name = filtered_array[2]
    elsif filtered_array.count > 3
      middle_name = filtered_array[1]
      last_name = filtered_array[2..-1].join(" ")
    end
  
    [first_name, middle_name, last_name, suffix_name]
  end

  def get_val(search_text, table)
   val = table.css("tr").select{|tr| tr.text.include? search_text}
   val[0].css("td")[1].text.squish
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def get_common(hash, run_id)
    {
      md5_hash:            create_md5_hash(hash),
      data_source_url:     "https://jccweb.jacksongov.org/inmatesearch/frmInmateDetails.aspx",
      run_id:              run_id,
      touched_run_id:      run_id
    }
  end

  def get_inmates_data(pp, run_id)
    table = pp.css("table")[1]
    data_hash = {}
    data_hash[:full_name]      = get_val("Name", table)
    first_name, middle_name, last_name, suffix_name = name_split(data_hash[:full_name])
    data_hash[:first_name]     = first_name
    data_hash[:middle_name]    = middle_name
    data_hash[:last_name]      = last_name
    data_hash[:suffix]         = suffix_name
    data_hash[:birthdate]      = get_val("DOB", table).gsub("/", "-")
    data_hash[:race]           = get_val("Race", table)
    data_hash[:sex]            = get_val("Sex", table)
    data_hash.merge!(get_common(data_hash, run_id))
    data_hash
  end

  def get_inmate_aliases(data_hash, inmate_id, run_id)
    aliases_hash = {}
    aliases_hash[:inmate_id]      = inmate_id
    aliases_hash[:full_name]      = data_hash[:full_name]
    aliases_hash[:first_name]     = data_hash[:first_name]
    aliases_hash[:middle_name]    = data_hash[:middle_name]
    aliases_hash[:last_name]      = data_hash[:last_name]
    aliases_hash[:suffix]         = data_hash[:suffix]
    aliases_hash.merge!(get_common(aliases_hash, run_id))
    aliases_hash
  end

  def get_inmates_id_data(pp, run_id, inmate_id)
    table = pp.css("table")[1]
    data_hash = {}
    data_hash[:inmate_id]    = inmate_id
    data_hash[:number]       = get_val("Master Number", table)
    data_hash.merge!(get_common(data_hash, run_id))
    data_hash
  end

  def get_inmates_id_additional(pp, inmate_id_id, run_id)
    table = pp.css("table")[1]
    data_array = []
    ["Race", "Sex"].each do |key|
      data_hash = {}
      data_hash[:inmate_ids_id] = inmate_id_id
      data_hash[:key]           = key
      data_hash[:value]           = get_val(key, table)
      data_hash.merge!(get_common(data_hash, run_id))
      data_array << data_hash
    end
    data_array
  end

  def get_arrests_data(run_id, inmate_id)
    data_hash               = {}
    data_hash[:inmate_id]   = inmate_id
    data_hash.merge!(get_common(data_hash, run_id))
    data_hash
  end

  def get_charges_data(pp, run_id, arrest_id)
    table = pp.css("table")[1]
    data_hash               = {}
    data_hash[:arrest_id]   = arrest_id
    data_hash[:number]      = get_val("Sequence Number", table)
    data_hash.merge!(get_common(data_hash, run_id))
    data_hash
  end

  def get_mugshots_data(run_id, inmate_id, aws_link)
    data_hash                 = {}
    data_hash[:inmate_id]     = inmate_id
    data_hash[:aws_link]      = aws_link
    data_hash[:original_link] = "https://jccweb.jacksongov.org/inmatesearch/frmGetInmateImage.aspx"
    data_hash.merge!(get_common(data_hash, run_id))
    data_hash
  end
end
