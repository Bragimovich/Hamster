# frozen_string_literal: true
class Parser < Hamster::Parser

  def parse_html(page)
    Nokogiri::HTML(page.force_encoding("utf-8"))
  end

  def get_inner_links(outer_page)
    outer_page = parse_html(outer_page)
    outer_page.css('#block-eeoc-uswds-content div.views-row h2 a').map{|a| a['href']}
  end

  def get_detail_link(inner_page)
    inner_page = parse_html(inner_page)
    inner_page.css('span.file a')[0]['href']
  end

  def fetch_link_for_inner_page(html)
    doc = parse_html(html)
    doc.css('div.grid-gap.grid-row span a')[0]["href"]
  end

  def get_brief_data(page, already_inserted_links, run_id)
    doc = parse_html(page)
    link = doc.css('head link')[0]["href"]
    return if already_inserted_links.include? link
    data_hash = {}
    cases                        = doc.css("#block-eeoc-uswds-content")
    data_hash[:case_title]       = cases.css('h1 span').text.strip
    data_hash[:case_nr]          = cases.css('div.guidance-details__wrapper p')[0].text.split(": ")[1].strip
    data_hash[:case_url]         = doc.css('head link')[0]["hrread_brief_urlef"] 
    data_hash[:date_filled]      = cases.css("div.guidance-details__wrapper p time")[0]["datetime"].split("T").first.to_date rescue nil
    data_hash[:brief_type]       = cases.css('div.guidance-details__wrapper p')[2].text.split(": ")[1].strip rescue nil
    data_hash[:statuses]         = cases.css('div.guidance-details__wrapper p')[3].text.split(": ")[1].squish.strip rescue nil
    data_hash[:bases]            = cases.css('div.guidance-details__wrapper p')[4].text.split(": ")[1].squish rescue nil
    data_hash[:case_court]       = cases.css('div.grid-gap.grid-row h2').text.strip
    data_hash[:case_url]         = link
    data_hash[:read_brief_url]   = "https://www.eeoc.gov" + doc.css('div.grid-gap.grid-row span a')[0]["href"] rescue nil
    data_hash[:data_source_url]  = "https://www.eeoc.gov/search/advanced-search?search_api_fulltext=&search_api_fulltext_1=&search_api_fulltext_2=&langcode=en&f%5B0%5D=content_type_2_%3Abriefs"
    data_hash = clean_data_hash(data_hash)
    data_hash[:run_id]           = run_id
    data_hash[:touched_run_id]   = run_id
    data_hash
  end

  def complete_record(data, record, url, run_id)
    data_hash = {}
    return [] if (data.nil?) || (data.empty?) || (data.class == Array)
    data_hash[:name]            = clean_data(data[:name])
    data_hash[:type]            = clean_data(data[:type])
    data_hash[:case_id]         = record[1]
    data_hash[:brief_url]       = url
    data_hash[:md5_hash]        = create_md5_hash(data_hash)
    data_hash[:run_id]          = run_id
    data_hash[:touched_run_id]  = run_id
    data_hash
  end
  
  def processed_pdf_files(file_path)
    reader = PDF::Reader.new(open(file_path)) rescue nil
    return [] if reader.nil?
    @data_html  = reader.pages.first.text.scan(/^.+/) rescue nil
    return [] if  @data_html.nil?
    reader.pages.each_with_index do |page, index|
      next if index == 0
      @data_html = @data_html + page.text.scan(/^.+/)
    end
    @doc = []
    parties_final_array  = fetch_parties
    eeoc_comission_array = eeoc_comission
    [parties_final_array, eeoc_comission_array]
  end

  def processed_html_files(file)
    @doc = parse_html(file)
    @data_html = []
    array      = []
    count      = @doc.css("p").count
    for line in 0..count
      data = @doc.css("p")[line] unless @doc.css("p")[line].nil?
      @data_html.append(data.text)
    end
    parties_final_array = fetch_parties
    eeoc_comission_array = eeoc_comission
    [parties_final_array, eeoc_comission_array]
  end

  def processed_text_files(file)
    @data_html = []
    array      = []
    file.each_line do |line|
      @data_html.append(line)
    end
    @doc = []
    parties_final_array  = fetch_parties
    eeoc_comission_array = eeoc_comission(false)
    [parties_final_array, eeoc_comission_array]
  end

  private

  def get_index_columns(party_type_search_start_index)
    second_party_data = ""
      @data_html[(party_type_search_start_index + 1)..].each do |line|
        second_party_data = line unless line.squish.empty?
        break unless second_party_data.empty?
      end
    line = second_party_data
    if (line.match?(/Appel|Respon|Defend|Plaintiff|Petitioner|Relator|PLAINTIFFS|DEFENDANT/))
      name  = line.split(",")[0..-2].join(", ")
      type  = line.split(",").last
    else
      name  = second_party_data.squish
      index = @data_html.select{|e| e.include? second_party_data}
      index = @data_html.index index[0]
      type  = @data_html[index + 1].squish.empty? ? @data_html[index + 2].squish : @data_html[index + 1].squish
    end
    [name, type, index]
  end

  def fetch_parties
    parties_final_array = []
    party_hash = {}
    party_type_search_start_index, first_party_type = get_party_data
    if first_party_type.strip.include? "\r\n" and first_party_type.count(",") > 1 and  first_party_type.scan(/Appel/).length < 2
      first_party_type, first_party_name = get_party_type(first_party_type)
      party_hash[:name] = first_party_name.squish
      party_hash[:type] = first_party_type.squish
      parties_final_array << party_hash
      party_hash = {}
      name, type, index = get_index_columns(party_type_search_start_index)
      party_hash[:name] = name.squish
      party_hash[:type] = type.squish
      parties_final_array << party_hash
      party_hash = {}
    else
      first_party_name = get_party_name(first_party_type)
    end
    party_hash[:name] = first_party_name.gsub(")", "")
    party_hash[:type] = first_party_type.split(",")[0].squish
    parties_final_array << party_hash
    party_hash = {}
    party_name = []
    type = ""
    @data_html[party_type_search_start_index+1..].each do |line|
      if (line.match?(/Appel|Respon|Defend|Plaintiff|Petitioner|Relator|_|APPEL/))
       type = line
       break
      end
      party_name << line
    end
    return parties_final_array if party_name.count > 10
    party_hash[:name] = party_name.join(" ").gsub(")", "").squish
    party_hash[:type] = type.split(",")[0].squish
    parties_final_array << party_hash
    party_hash = {}
    for i in 1..3 do
      check_index = @data_html.select{|e| e.include? type}
      party_name  = []
      type  = ""
      index = @data_html.index check_index[0]
      @data_html[index+1..].each do |line|
        if (line.match?(/Appel|Respon|Defend|Plaintiff|Petitioner|Relator/))
         type = line
         break
        end
        party_name << line
      end
      break if party_name.count > 5 or type.length > 40
      party_hash[:name] = party_name.join(" ").gsub(")", "").squish
      party_hash[:type] = type.split(",")[0].squish
      parties_final_array << party_hash
      party_hash = {}
    end
    parties_final_array
  end

  def get_party_name(first_party_type)
    party_name_start_index = @data_html.select{|e| e.include? first_party_type}
    party_name_start_index = @data_html.index party_name_start_index[0]
    first_party_name       = []
    range                  = party_name_start_index-1..1
    for i in (range.first).downto(range.last).each do
      first_party_name << @data_html[i] unless (@data_html[i].squish.gsub(/[)_]/, "").empty?) || (@data_html[i].match?(/CIRCUIT|DISTRICT/))
      break if ((@data_html[i].squish.gsub(")", "").empty?) || (@data_html[i].match?(/CIRCUIT|DISTRICT|___________/))) && (!first_party_name.empty?)
    end
    first_party_name.reverse.reject{|e| e.squish.empty?}.join(" ").squish
  end

  def get_party_type(first_party_type)
    first_party_type  = first_party_type.split(",")
    first_party_name  = first_party_type[0..-2].join(", ").squish
    first_party_type  = first_party_type.last
    [first_party_type, first_party_name]
  end

  def get_party_data
    party_type_search_start_index = @data_html.select{|e| e.squish.start_with? "v." or e.squish.start_with? "vs." or e.squish.start_with? "versus" or e.squish.start_with? "V."}
    return [] if party_type_search_start_index.empty?
    party_type_search_start_index = @data_html.index party_type_search_start_index[0]
    first_party_type = ""
    range = party_type_search_start_index-1..1
    for i in (range.first).downto(range.last).each do
      first_party_type = @data_html[i].split(")")[0] unless  @data_html[i].squish.gsub(")", "").empty? or @data_html[i].split("  ")[0].count("0-9") > 1
      break unless first_party_type.empty?
    end
    [party_type_search_start_index, first_party_type]
  end

  def eeoc_comission(is_html = true)
    check_index  = @data_html.select{|e| e.squish.start_with?("TABLE OF CONTENTS")}
    check_index  = @data_html.select{|e| e.squish.start_with?("STATEMENT OF INTEREST")} if check_index.empty?
    index_table  = @data_html.index check_index[0] unless check_index.empty?
    index_table  = @data_html.count if check_index.empty?
    data         = @data_html[0..-1]
    array        = []
    search_array = ["Supervisory Trial Attorney", "Solicitor of Labor","Associate Solicitor", "Acting General Counsel", "Appellate Attorney", "Deputy Solicitor for National Operations", "Assistant U.S. Attorney", "Deputy General Counsel", "Acting Deputy General Counsel", "Acting Assistant General Counsel", "Acting Associate General Counsel", "Attorney", "Senior Attorney", "General Counsel", "Associate General Counsel", "Assistant General Counsel", "Assistant Attorney General"]
    search_array.each do |search_text|
      result = find_comission(@doc, data, search_text, is_html)
      array << result unless result.empty?
    end
    array
  end
  
  def find_comission(file, data, search_key, is_html)
    array = []
    hash  = {}
    check_index = data.select{|e| e.squish.start_with?(search_key)}
    return hash if check_index.empty?
    index = data.index check_index[0]
    if is_html && (check_index[0].include? "\r\n")
      data = @data_html.map{|e| e = e.gsub(/\r\n/," ")}
      type = data[index].gsub("/\s+/","/").squish.split(" ")[0].gsub("/"," ")
      return hash if  (data[index-1].gsub(" ","/").squish.split(" ")[0].nil? and file.css('p')[index].previous_element.text.nil?)
      name        = file.css('p')[index].previous_element.text.gsub(/\u00a0/,'|').split('||').reject{|e| e.empty?}[0].gsub('|','').squish.lstrip rescue ""
      name        = name.empty? ? file.css('p')[index].previous_element.text.gsub(/\u00a0/,'|').split('||').reject{|e| e.empty?}[0].gsub('|','').squish.lstrip : name
      hash[:name] = name
      hash[:type] = search_key
      array << hash
      return array
    end
    type = data[index].split("  ")
    type = type.reject { |c| c.empty? } 
    if type.count < 2 
      type = data[index].split("\t")
    end
    type = type.reject { |c| c.empty? }
    if type.count > 1 
      if type[1].squish.start_with?("Attorney")
        first_type  = type[1].squish
        get_name    = data[index-1].split("  ")
        get_name    = get_name.reject { |c| c.empty? }
        if get_name.count < 2
          get_name  = data[index-1].split("\t")
        end
        get_name    = get_name.reject { |c| c.empty? }
        get_name    = get_name[1].squish
        return hash if (!(get_name = get_name.upcase) or get_name.count("0-9") > 0)
        hash[:name] = get_name
        hash[:type] = first_type
        array << hash 
        hash = {}
      end
    end
    type = type[0].squish
    name =  data[index-1].gsub(/\u00a0/,' ').lstrip.split('  ').reject{|e| e.empty?}
    name = name[0].nil? ? data[index-2].gsub(/\u00a0/,' ').lstrip.split('  ').reject{|e| e.empty?} : name
    name = name[0].squish.empty? ? data[index-2].gsub(/\u00a0/,' ').lstrip.split('  ').reject{|e| e.empty?} : name
    name = name.reject { |c| c.empty? }
    if name.count > 1 
      if name[1].squish.start_with?("Attorney")
        first_type  = name[1].squish
        get_name    = data[index-2].split("  ")
        get_name    = get_name.reject { |c| c.empty? }
        if get_name.count < 2
          get_name  = data[index-1].split("\t")
        end
        get_name    = get_name.reject { |c| c.empty? }
        get_name    = get_name[1].squish rescue nil
        get_name    = get_name.nil? ? name[0].split("  ")[0].squish : get_name
        return hash if (get_name.nil? or get_name.count("0-9") > 0 or !(get_name = get_name.upcase))
        hash[:name] = get_name
        hash[:type] = first_type
        array << hash 
        hash = {}
      end
    end
    name = name[0].lstrip.split("\t")[0].squish rescue ""
    return hash if (!(name = name.upcase) or name.count("0-9") > 0)
    hash[:name] = name
    hash[:type] = search_key
    array << hash
    array
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def clean_data_hash(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

  def clean_data(data)
    return nil if (data.nil? or data.empty?)
    data = data.gsub("_", "")
    data = (data.squish.end_with? "," or data.squish.end_with? "." or data.squish.end_with? ")" or data.squish.end_with? ";" or data.squish.end_with? ":")? data.squish[..-2] : data
    data = (data.squish.start_with? "v.")? data.squish[2..] : data
    data = (data.squish.start_with? "and")? data.squish[4..] : data
    data.squish rescue nil
  end
end
