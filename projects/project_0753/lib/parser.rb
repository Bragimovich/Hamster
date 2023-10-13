# frozen_string_literal: true

class Parser < Hamster::Parser
  def parse_page(response)
    Nokogiri::HTML(response)
  end

  def file_data_check(file)
    body = parse_page(file)
    body.css('div.sc_tabs')
  end

  def get_tabs(page)
    page.css('input[type="radio"]')
  end

  def get_main_page_link(page)
    res = parse_page(page)
    res.css("a").map{ |a| a["href"]}.select{ |a| a.include?("senator") || a.include?("representative") }
  end

  def get_senate_house_links(response)
    response.css("a").map{ |a| a["href"]}.select{ |a| a.include?("senator") || a.include?("representative") }
  end

  def get_outer_details(page, link, res, run_id)
    raw_senate_hash = raw_senate_person(page, link, run_id)
    raw_hash        = raw_person(page, link, res, run_id)
    [raw_senate_hash, raw_hash].compact
  end

  def get_house_person_details(html, link, run_id)
    raw_house_hash  = raw_house_person(html, link, run_id)
  end

  def fetch_data(document, link, run_id, cong_num)
    table_count = document.css('table.sc_table').count

    raw_score_vote_hash, raw_score_vote_md5_array = raw_score_vote(document, 0, link, run_id, cong_num)
    raw_activities_hash, raw_activities_md5_array = raw_activities(document, table_count == 2 ? 1 : 2, link, run_id, cong_num)
    if table_count == 3
      raw_past_votes_hash, raw_past_votes_md5_array = raw_score_vote(document, 1, link, run_id, cong_num)
    end
    process_tables(raw_score_vote_hash, raw_past_votes_hash, raw_score_vote_md5_array, raw_past_votes_md5_array, raw_activities_hash, raw_activities_md5_array)
  end

  def raw_senate_person(page, link, run_id)
    data_hash = {}
    data_hash[:start_year]      = get_tabs(page)[-1].next_element.text.split('-').first.to_i rescue nil
    data_hash[:finish_year]     = get_tabs(page)[-1].next_element.text.split('-').last.to_i  rescue nil
    data_hash[:description]     = page.css('div.sc_bio_congress').text.strip
    data_hash[:md5_hash]        = create_md5_hash(data_hash)
    data_hash[:run_id]          = run_id
    data_hash[:touched_run_id]  = run_id
    data_hash[:data_source_url] = link
    data_hash
  end

  def raw_person(page, link, res, run_id)
    data_hash = {}
    states    = get_states_Abbreviation(res)
    data_hash[:person_name]       = split_name(page)
    data_hash[:party]             = page.css('div.col-sm-7 p').text.split(' ').last.delete('()')
    state_text = page.css('div.col-sm-7 p')[0].text
    if link.include? ("representative")
      data_hash[:state] = state_text.split('-').first.strip
    else
      state_name         = state_text.split('(').first.strip
      state_hash         = get_state_hash(state_name, states)
      data_hash[:state]  = state_hash[:abbreviation]
    end
    data_hash[:district]          = is_senator?(link) ? nil : page.css('div.col-sm-7 p').text.split.first.split('-').last 
    rating_text                   = page.css('div.sc_rating').text.split(':').last.strip
    data_hash[:rating]            = rating_text == "N/A" ? nil : rating_text
    data_hash[:senate_or_house]   = is_senator?(link) ? link.split('/')[-2].gsub!("senator", "senate") : link.split('/')[-2].gsub!("representative", "house")
    data_hash[:position]          = page.css('div.sc_name_large h1').text.split('.').first.strip
    data_hash[:md5_hash]          = create_md5_hash(data_hash)
    data_hash[:run_id]            = run_id
    data_hash[:touched_run_id]    = run_id
    data_hash[:data_source_url]   = link
    data_hash
  end

  def raw_house_person(html, link, run_id)
    data_hash = {}
    data_hash[:congress_number]   = html.css('h2')[0].text.split('th').first.to_i
    data_hash[:description]       = html.css('div.sc_bio p').text.strip.empty? ? nil : html.css('div.sc_bio p').text.strip
    data_hash[:md5_hash]          = create_md5_hash(data_hash)
    data_hash[:run_id]            = run_id
    data_hash[:touched_run_id]    = run_id
    data_hash[:data_source_url]   = link
    data_hash
  end

  def raw_score_vote(document, table_index, link, run_id, cong_num)
    table_rows = get_table_rows(document, table_index)
    vote_type  = past_votes_check(document, table_index)
    score_votes_array = []
    raw_score_vote_md5_array = []
    table_rows[1..-1].each do |row|
      data_hash = {}
      wrong_date                    = is_senator?(link) ? row.css("td strong")[0].text.strip : row.css("td")[0].text.strip
      date                          = Date.strptime(wrong_date, '%m/%d/%Y')
      data_hash[:vote_date]         = date.strftime('%Y-%m-%d')
      data_hash[:congress_number]   = is_senator?(link) ? row.css('span.date_congress').text.split('th').first.to_i : cong_num.to_i
      data_hash[:vote_name]         = row.css("td h3").text.strip
      data_hash[:vote_desc]         = row.css("td")[1].children[1..2].text.split('. ').join('.').strip
      data_hash[:score]             = row.css("img[data-lazy-src*='sc_nv'], img[data-lazy-src*='sc_cross']").empty? ? 1 : 0
      data_hash[:rl_link]           = row.css('a').map{ |a| a["href"]}.first
      data_hash[:pr_link]           = row.css('a').map{ |a| a["href"]}.last
      data_hash[:past]              = vote_type
      data_hash[:md5_hash]          = create_md5_hash(data_hash)
      raw_score_vote_md5_array << data_hash[:md5_hash]
      data_hash[:run_id]            = run_id
      data_hash[:touched_run_id]    = run_id
      data_hash[:data_source_url]   = link
      score_votes_array << data_hash
    end
    [score_votes_array, raw_score_vote_md5_array]
  end

  def get_table_rows(document, table_index)
    table = document.css('table.sc_table')[table_index]
    rows  = table.css('tr')
    rows
  end
  
  def past_votes_check(document, table_index)
    (document.css('table.sc_table')[table_index].previous_sibling.text == 'Important Past Votes') ? 1 : 0
  end

  def raw_activities(document, table_index, link, run_id, cong_num)
    table_rows = get_table_rows(document, table_index)
    data_array = []
    raw_activities_md5_array = []
    table_rows[1..-1].each do |row|
      data_hash = {}
      data_hash[:congress_number]   = is_senator?(link) ? row.css('span.date_congress').text.split('th').first.to_i : cong_num.to_i
      data_hash[:vote_name]         = row.css("td h3").text.strip
      data_hash[:vote_desc]         = row.css("td")[1].children[1..2].text.split('. ').join('.').strip
      data_hash[:score]             = row.css("img[data-lazy-src*='sc_nv'], img[data-lazy-src*='sc_cross']").empty? ? 1 : 0
      data_hash[:pr_link]           = row.css('a').map{ |a| a["href"]}.last
      data_hash[:md5_hash]          = create_md5_hash(data_hash)
      raw_activities_md5_array << data_hash[:md5_hash]
      data_hash[:run_id]            = run_id
      data_hash[:touched_run_id]    = run_id  
      data_hash[:data_source_url]   = link
      data_array << data_hash 
    end
    [data_array, raw_activities_md5_array]
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  private

  def process_tables(raw_score_vote_hash, raw_past_votes_hash, raw_score_vote_md5_array, raw_past_votes_md5_array, raw_activities_hash, raw_activities_md5_array)
    raw_vote_data_combined = raw_past_votes_hash.nil? || raw_past_votes_hash.empty? ? raw_score_vote_hash : raw_score_vote_hash + raw_past_votes_hash
    raw_vote_md5_combined = raw_past_votes_md5_array.nil? ? raw_score_vote_md5_array : raw_score_vote_md5_array + raw_past_votes_md5_array

    [raw_vote_data_combined, raw_activities_hash, raw_vote_md5_combined, raw_activities_md5_array].compact
  end

  def split_name(page)
    string = page.css('div.sc_name_large h1')[0].text.gsub('"', '')
    first_dot_index = string.index('.')
    second_part = string[(first_dot_index+1)..-1].strip
  end

  def get_state_hash(state_name, states)
    state_hash = {}
    states.each do |state|
      if state_name.downcase == state[:name].downcase
        state_abbreviation = state[:abbreviation]
        state_hash[:name] = state_name
        state_hash[:abbreviation] = state_abbreviation
      end
    end
    state_hash
  end

  def get_states_Abbreviation(res)
    states_array = []
    ul_tag = res.css('div.entry-content ul').first
    li_tags = ul_tag.css('li') rescue []
    li_tags.each do |li|
      txt = li.text
      state_name, state_abbreviation = txt.split(' (')
      state_abbreviation.chop!
      states_array << {name: state_name.strip, abbreviation: state_abbreviation}
    end
    states_array
  end

  def is_senator?(link)
    link.include?("senator")
  end
end
