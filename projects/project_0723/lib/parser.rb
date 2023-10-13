# frozen_string_literal: true

class Parser < Hamster::Parser

  def parse_html(body)
    Nokogiri::HTML(body, 'UTF-8')
  end

  def get_school_links(body)
    body.css('p.nospace a').map{|e| e['href']}
  end

  def get_box_scores_link(page)
    data_array = []
    history_rows =  page.css('table.dg tr')
    history_rows.each do |row|
      history_row = row.css("td")
      next if history_row.text.empty? or history_row[0].text == "2019-20"
      links_div = history_row[-1].css("a")
      links_div.each_with_index do |link, ind|
        data_hash = {}
        ind + 1
        main_url = "https://ihsa.org"
        link_url = "#{main_url}#{link['href']}"
        file_name = link['href'].gsub("/archive/ba/","").gsub(".htm","").gsub("/","_").gsub("box","_")
        data_hash['link_url'] = link_url
        data_hash['file_name'] = file_name
        data_array.push(data_hash)
      end
    end
    data_array
  end

  def school_data_parser(page, run_id, link)
    @run_id = run_id
    @data_source_url = link
    data_hash = {}
    school_contact = fetch_school_contact(page)
    school = fetch_school(page)
    persons_contacts = fetch_persons_contacts(page)
    data_hash = {
      'school' => school,
      'school_contact' => school_contact,
      'persons_and_contact' => persons_contacts,
    }
  end

  def baseball_data_parser(page, run_id, link)
    @run_id = run_id
    @data_source_url = link
    data_hash = {}
    all_data_rows = page.css("pre").first.text.split("\r\n")
    ex_raw_data = fetch_extra_columns(all_data_rows)
    parse_extra_columns(ex_raw_data)
    player_rows, headers = fetch_player_scores(all_data_rows)
    players = parse_player_scores(player_rows, headers)
    description = fetch_description(all_data_rows)
    player_innings, headers = fetch_innings(all_data_rows)
    innings = parse_innings(player_innings, headers)
    player_score_details, headers = fetch_score_details(all_data_rows)
    player_scores = parse_score_details(player_score_details, headers)
    data_hash = {
      'Players_Scores' => players,
      'Description' => description,
      'Innings' => innings,
      'Scores_Details' => player_scores,
    }
  end

  def get_csv_schools(file, run_id)
    @run_id = run_id
    doc = File.read(file)
    all_data = CSV.parse(doc, :headers => true)
    hash_array = []
    all_data.each do |row|
      data_hash = {}
      data_hash["aliase_name"]      = row["School clean"]
      data_hash["alias1"]           = row["Alias"]
      data_hash["alias2"]           = row["Alias 2"]
      data_hash["alias3"]           = row["Alias 3"]
      hash_array.push(data_hash)
    end
    hash_array
  end

  def get_link_alias(page, url)
    hash_array = []
    all_p_tags = page.css("p.nospace")
    all_p_tags.each do |p|
      link = p.css("a").attr('href').text
      next if link.include?("schools/2848.htm")
      data_hash = {}
      next unless p.text.include?("\u0097")
      data_hash["alias"] = p.text.split(/\,\s*see/).first.gsub("\u0097","").strip
      data_hash["school_page_url"] = link
      data_hash["data_source_url"] = url
      hash_array.push(data_hash)
    end
    hash_array
  end

  private 
  
  def fetch_school(page)
    data_hash = {}
    data_hash['name'] = page.css('h1').text.strip 
    data_hash['aliase_name'] = page.css('p.nospace.b').last.text.strip
    data_hash['enrollment'] = info_by_keys(page, "Enrollment:")
    data_hash['nicknames'] = info_by_keys(page, 'Nickname(s):')
    data_hash['colors'] = info_by_keys(page, 'Colors:')
    data_hash['school_type'] = info_by_keys(page, 'School Type:')
    data_hash['conferences'] = info_by_keys(page, 'Conference(s):')
    data_hash['county'] = info_by_keys(page, 'County:')
    data_hash['cities_in_district'] = info_by_keys(page, 'Cities in District:')
    data_hash['broad_division'] = info_by_keys(page, 'Board Division:')
    data_hash['legislative_district'] = info_by_keys(page, 'Legislative District:')
    data_hash['run_id'] = @run_id
    data_hash['data_source_url'] = @data_source_url
    data_hash
  end
  
  def fetch_school_contact(page)
    data_hash = {}
    street, full_address = fetch_address(page)
    data_hash['full_address'] = full_address
    data_hash['street_address'] = street
    data_hash['phone'] = info_by_keys(page, "Phone:")
    data_hash['fax'] = info_by_keys(page, 'Fax:')
    data_hash['email'] = info_by_keys(page, 'Email:')
    data_hash['website'] = info_by_keys(page, 'School Web Site:')
    data_hash['run_id'] = @run_id
    data_hash['data_source_url'] = @data_source_url
    data_hash
  end

  def fetch_persons_contacts(page)
    data_array = []
    all_body_childs = page.css("body > *")
    persons_flag = false
    section = ""
    all_body_childs.each do |child|
      persons_flag = true if !persons_flag && child.name == 'h3'
      next unless persons_flag
      if child.name == 'h3'
        section = child.text.strip
      elsif child.name == 'p'
        collon_split = child.text.split(':')
        next if collon_split.last.split[0..1].include?("TBA")
        full_name = collon_split.last.split[0..1].join(' ') 
        first_name = collon_split.last.split[0].strip
        last_name = collon_split.last.split[1].strip
        vacation = collon_split.first.strip 
        email = child.text.scan(/(?!.*?\.\.)[\w.]+@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]+/).first
        if child.text.include?('phone') and child.text.include?('fax')
          phone = child.text.split('phone').last.split('fax').first.strip
          fax   = child.text.split('fax').last.strip
        elsif child.text.include?('phone')
          phone = child.text.split('phone').last.gsub(/\s*/, '')
          fax = nil
        else
          phone = nil 
          fax = nil
        end
        person_hash = {}
        person_hash['section']    = section
        person_hash['full_name']  = full_name
        person_hash['first_name'] = first_name
        person_hash['last_name']  = last_name
        person_hash['vacation']   = vacation
        person_hash['run_id']     = @run_id
        person_hash['data_source_url'] = @data_source_url
        contact_hash = {}
        contact_hash['phone'] = phone
        contact_hash['email'] = email
        contact_hash['fax']   = fax
        contact_hash['run_id'] = @run_id
        contact_hash['data_source_url'] = @data_source_url

        data_array.push([person_hash, contact_hash])
      end
    end
    data_array
  end

  def fetch_innings(all_data_rows)
    player_innings = []
    innings_flag = false
    dash_row_count = 0
    headers = ''
    all_data_rows.each do |data_row|
      if data_row.include? "Score by Inning"
        headers = data_row.gsub('Score by Innings','').gsub('Score by Inning','').gsub("\r",'').strip
        innings_flag = true 
        next
      end
      dash_row_count += 1 if data_row.strip.split(/[-]{2,}/).empty? and innings_flag
      innings_flag = false if dash_row_count > 1
      next if !innings_flag or data_row.strip.split(/[-]{2,}/).empty?
      player_innings.push(data_row.gsub("\r",""))
    end
    [player_innings, headers]
  end

  def parse_innings(player_innings, headers)
    innings = []
    player_innings.each do |player_inning|
      inning_hash = {}
      school_name = player_inning.scan(/\s*\A(.+?)\s*\d/).first.first.strip.sub(/\.*\z/, '')
      if player_inning.include?(".")
        inning_row = player_inning.split('.').last.split
      else
        inning_row = player_inning.gsub(school_name, "").split
      end
      inning_row.shift if inning_row[0].scan(/^\d+$/).empty?
      headers_count = inning_row.find_index("-")
      schema = inning_row[0..headers_count].join(" ")
      inning_scores_row = inning_row[headers_count+1..-1]
      headers.split.each_with_index do |header, index|
        inning_hash['scheme']  = schema
        inning_hash[header] = inning_scores_row[index]
      end
      inning_hash['data_source_url'] = @data_source_url
      inning_hash['ex_school_name'] = school_name
      inning_hash['ex_vs_school_name_1'] = @ex_vs_school_name_1
      inning_hash['ex_vs_school_name_2'] = @ex_vs_school_name_2
      inning_hash['ex_school_score_1'] = @ex_school_score_1
      inning_hash['ex_school_score_2'] = @ex_school_score_2
      inning_hash['ex_date_and_loc'] = @ex_date_and_loc
      inning_hash['ex_raw_data'] = @ex_raw_data
      inning_hash['run_id'] = @run_id
      innings.push(inning_hash)
    end
    innings
  end

  def fetch_score_details(all_data_rows)
    player_score_details = []
    school_names = []
    data_hash = {}
    score_flag = false
    side_by_side_check = false
    headers = ''
    all_data_rows.each do |data_row|
      unless data_row.scan(/IP\s+H\s+R\s+/).empty?
        side_by_side_check = true if data_row.scan(/IP\s+H\s+R\s+/).count > 1
        headers = data_row.split("   ").last.gsub("\r","").strip
        school_names = data_row.split(headers).map{|e| e.strip}
        score_flag = true 
        next
      end
      data_row = data_row.gsub("\r",'')
      score_flag = false if data_row.empty?
      next if !score_flag or data_row.gsub("-","").strip.empty?
      if side_by_side_check
        data_row_array = data_row.split(/\s{4,}/).reject{|e| e.empty?}
        data_row_array.each_with_index do |row, index|
          if data_row_array.count == 1
            school_name = data_row.scan(/^\s{6,}/).count == 1 ? school_names[1] : school_names[0] 
          else
            school_name = school_names[index]
          end
          player_scores = row.scan(/(?<!\S)\d+(?:\.\d+)?(?:\s+\d+(?:\.\d+)?)*(?!\S)/).first
          player_name = row.scan(/\s*\A(.+?)\s*\d/).first[0].sub(/\.*\z/, '').strip
          data = [player_name, player_scores]
          data_hash = {school_name => data}
          player_score_details.push(data_hash)
        end
      else
        player_scores = data_row.scan(/(?<!\S)\d+(?:\.\d+)?(?:\s+\d+(?:\.\d+)?)*(?!\S)/).first
        player_name = data_row.scan(/\s*\A(.+?)\s*\d/).first[0].sub(/\.*\z/, '').strip
        school_name = school_names.first
        data = [player_name, player_scores]
        data_hash = {school_name => data}
        player_score_details.push(data_hash)
      end
    end
    [player_score_details, headers]
  end

  def parse_score_details(player_score_details, headers)
    scores = []
    player_score_details.each do |player_score|
      score_hash = {}
      school_name = player_score.keys.first
      player_name = player_score.values.first[0]
      player_name = player_score.values.first[0].slice(0..-3).strip if player_name[-1].include?(",")
      score_row = player_score.values.first[1].split
      headers.split.each_with_index do |header, index|
        score_hash[header] = score_row[index]
      end
      score_hash['data_source_url'] = @data_source_url
      score_hash['ex_school_name'] = school_name
      score_hash['ex_player_name'] = player_name
      score_hash['ex_vs_school_name_1'] = @ex_vs_school_name_1
      score_hash['ex_vs_school_name_2'] = @ex_vs_school_name_2
      score_hash['ex_school_score_1'] = @ex_school_score_1
      score_hash['ex_school_score_2'] = @ex_school_score_2
      score_hash['ex_date_and_loc'] = @ex_date_and_loc
      score_hash['ex_raw_data'] = @ex_raw_data
      score_hash['run_id'] = @run_id
      scores.push(score_hash)
    end
    scores
  end

  def fetch_description(all_data_rows)
    desc_array = []
    desc_data_array = []
    desc_hash = {}
    desc_flag = false
    all_data_rows.each do |data_row|
      desc_flag = true if !data_row.scan(/^\s*E\s*-/).empty? or !data_row.scan(/^\s*Win\s*-/).empty? or !data_row.scan(/^\s*WP\s*-/).empty? or !data_row.scan(/^\s*Umpires\s*-/).empty?
      data_row = data_row.gsub("\r",'').strip
      desc_flag = false if data_row.empty?
      next unless desc_flag
      desc_array.push(data_row)
    end
    desc_row = desc_array.join(" ")
    desc_hash['descriptions'] = desc_row
    desc_hash['data_source_url'] = @data_source_url
    desc_hash['ex_vs_school_name_1'] = @ex_vs_school_name_1
    desc_hash['ex_vs_school_name_2'] = @ex_vs_school_name_2
    desc_hash['ex_school_score_1'] = @ex_school_score_1
    desc_hash['ex_school_score_2'] = @ex_school_score_2
    desc_hash['ex_date_and_loc'] = @ex_date_and_loc
    desc_hash['ex_raw_data'] = @ex_raw_data
    desc_hash['run_id'] = @run_id
    desc_data_array.push(desc_hash)
  end

  def fetch_player_scores(all_data_rows)
    players_rows = []
    headers = ''
    player_1_flag = false
    player_2_flag = false
    side_by_side_check = false
    all_data_rows.each do |data_row|
      if data_row.include? "Player"
        side_by_side_check = true if data_row.scan(/Player/).count > 1
        headers = data_row.gsub('Players','').gsub('Player','').gsub("\r",'').strip.split(/[\s]{3,}/).first
        player_1_flag = true 
        next
      end
      player_1_flag = false if data_row.include? "Total"
      player_2_flag = true if data_row.include? "Total"
      next if !player_1_flag or data_row.strip.split(/[-]{2,}/).empty?
      next if data_row.gsub("-","").strip.empty?
      if side_by_side_check
        data_row_array = data_row.split(/\s{4,}/).reject{|e| e.empty?}
        school_name = nil
        data_row_array.each_with_index do |row, indx|
          if data_row_array.count == 1
            school_name = data_row.scan(/^\s{6,}/).count == 1 ? @ex_vs_school_name_2 : @ex_vs_school_name_1 
          else
            school_name = indx == 0 ? @ex_vs_school_name_1 : @ex_vs_school_name_2
          end
          row_hash = {school_name => row.gsub("\r","")}
          players_rows.push(row_hash)
        end
      else
        school_name = player_1_flag ? @ex_vs_school_name_1 : @ex_vs_school_name_2
        row_hash = {school_name => data_row.gsub("\r","")}
        players_rows.push(row_hash)
      end
    end
    [players_rows, headers]
  end

  def parse_player_scores(player_rows, headers)
    players = []
    player_rows.each do |player_row|
      player_hash = {}
      scores_row = player_row.values.first.scan(/(?<!\S)\d+(?:\.\d+)?(?:\s+\d+(?:\.\d+)?)*(?!\S)/).first
      name = player_row.values.first.gsub(scores_row,"").strip.sub(/\.*\z/, '').split
      player_hash['full_name'] = name[0..-2].join(" ")
      player_hash['section'] = 'Roster'
      player_hash['data_source_url'] = @data_source_url
      player_hash['run_id'] = @run_id
      score_hash = {}
      score_hash['pos']  = name[-1].strip
      score_hash['data_source_url'] = @data_source_url
      score_hash['ex_school_name'] = player_row.keys.first
      score_hash['ex_vs_school_name_1'] = @ex_vs_school_name_1
      score_hash['ex_vs_school_name_2'] = @ex_vs_school_name_2
      score_hash['ex_school_score_1'] = @ex_school_score_1
      score_hash['ex_school_score_2'] = @ex_school_score_2
      score_hash['ex_date_and_loc'] = @ex_date_and_loc
      score_hash['ex_raw_data'] = @ex_raw_data
      score_hash['run_id'] = @run_id
      scores_row = scores_row.split
      headers.split.each_with_index do |header, index|
        score_hash[header] = scores_row[index]
      end
      players.push([player_hash, score_hash])
    end
    players
  end

  def fetch_extra_columns(all_data_rows)
    player_1_flag = false
    player_2_flag = false
    side_by_side_check = false
    total_row_flag = false
    ex_raw_data = []
    all_data_rows.each do |data_row|
      next if data_row.gsub("-","").strip.empty?
      if (data_row.include? "Player") && !player_1_flag
        side_by_side_check = true if data_row.scan(/Player/).count > 1
        player_1_flag = true 
        next
      end
      player_2_flag = true if (data_row.include? "Player") && player_1_flag
      break if side_by_side_check or player_2_flag
      ex_raw_data.push(data_row.gsub("\r","").strip) if !player_1_flag or total_row_flag
      total_row_flag = true if data_row.include? "Total"
    end
    ex_raw_data.reject{|e| e.empty?}.push(side_by_side_check)
  end

  def parse_extra_columns(ex_raw_data)
    @ex_vs_school_name_1, @ex_vs_school_name_2, @ex_school_score_1, @ex_school_score_2, @ex_date_and_loc = nil
    @ex_raw_data = ex_raw_data
    schools = []
    at_flag = false
    at_flag = true if ex_raw_data.select{ |e| e.to_s.downcase.include?  ' at ' }.count > 1
    if at_flag
      schools_row = ex_raw_data.select{ |e| e.to_s.downcase.include?  ' at ' }.first
    else
      schools_row = ex_raw_data.select{ |e| e.to_s.downcase.include?  ' vs ' }.first
    end
    unless schools_row.nil?
      schools = schools_row.split(" vs ") if !at_flag
      schools = schools_row.split(" Vs ") if schools.count != 2 and !at_flag
      schools = schools_row.split(" VS ") if schools.count != 2 and !at_flag
      schools = schools_row.split(" at ") if at_flag
      @ex_vs_school_name_1 = schools.first.strip
      @ex_vs_school_name_2 = schools.last.strip
    end 
    side_by_side_check = ex_raw_data.last 
    if side_by_side_check
      school_scores = ex_raw_data[-2].split(/[\s]{6,}/)
      @ex_school_score_1 = school_scores[0].strip
      @ex_school_score_2 = school_scores[1].strip
      @ex_date_and_loc = ex_raw_data[-3].strip
    else
      @ex_school_score_1 = ex_raw_data[-3].strip
      @ex_school_score_2 = ex_raw_data[-2].strip
      @ex_date_and_loc = ex_raw_data[-4].strip
    end
  end

  def info_by_keys(page, key)
    check_key = page.css('p.nospace').find{|e| e.text.include?(key)}
    if key == "Board Division:" 
      check_key.text.split(',').first.split(':').last.strip rescue nil
    elsif key == "Legislative District:"
      check_key.text.split(',').last.split(':').last.strip rescue nil
    else
      check_key.text.split(':').last.strip rescue nil
    end
  end

  def fetch_address(page)
    check_key = page.css('p.nospace').find{|e| e.text.include?("(Google map, other maps)")}
    street_address = page.css('p.nospace').find{|e| e.text.include?("(Google map, other maps)")}
    street_address = page.css('p.nospace').find{|e| e.text.include?("()")} if check_key.nil?
    street = street_address.text.gsub("(Google map, other maps)", '').gsub("()","").gsub('\r\n\r\n','').strip
    full_address = [street, street_address.next_element.text.strip].join(' ')
    [street, full_address]
  end

end
