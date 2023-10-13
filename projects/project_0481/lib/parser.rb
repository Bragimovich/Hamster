# frozen_string_literal: true
class Parser < Hamster::Parser


  def parse_nokogiri(html)
    Nokogiri::HTML(html.force_encoding("utf-8"))
  end

  def get_verification_token(page)
    page.css('div.contentcontainer strong').text
  end

  def get_links(html)
    page = parse_nokogiri(html)
    page.css('div.divOATableCaption a').map{|a| a['href']}.select{|link| link.include? 'caseID='}.uniq
  end

  def get_dates(html,count)
    page = parse_nokogiri(html)
    dates = []
    (0...count).each do |counter|
      dates.append(page.css('div.divOATableCell')[2+(counter*5)].text.squish)
    end
    dates
  end

  def prepare_info_hash(main_page, page, link, date, run_id)
    case_id, name, link,date = get_outer_info(main_page, link ,date)
    full_lower_case_id = get_value(page , 'Cause Numbers:')
    lower_case_id = get_lower_ids(full_lower_case_id).first rescue nil 
    data_hash = {
      court_id: 405,
      case_id: case_id,
      case_name:  name,
      lower_case_id: lower_case_id,
      full_lower_case_id: full_lower_case_id,
      data_source_url: "https://www.appeals2.az.gov/ODSPlus/#{link}",
      case_filed_date: date
    }
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def get_aws(page, run_id, s3, raw_html)
    case_id, name, link = @basic_details
    key = "us_courts_expansion_405_#{case_id.split.join('_')}_info.html"
    data_hash = {
      court_id: 405,
      case_id: case_id,
      source_type: "info",
      aws_html_link: s3.put_file(raw_html, key, metadata={}),
      data_source_url: "https://www.appeals2.az.gov/ODSPlus/#{link}"
    }
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end

  def get_case_activities(page, run_id)
    activity_array = []
    case_id, name, link ,date = @basic_details
    proceeding_table = get_table(page, "Proceedings")
    return [] if proceeding_table.nil?
    proceeding_table.css('tr').each_with_index do |values, index|
      next if index < 2
      break if values.css('td').text.include? 'No Proceedings Available'
      value = values.css('td').map{|a| a.text.squish}
      type = value[0]
      date = date_conversion(value[1])
      activity = value[2]
      data_hash = {
        court_id: 405,
        case_id: case_id,
        activity_date: date,
        activity_type: type,
        activity_desc: activity,
        data_source_url: "https://www.appeals2.az.gov/ODSPlus/#{link}"
      }
      data_hash = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      activity_array << data_hash
    end
    activity_array
  end

  def prepare_additional_info_hash(page, run_id)
    case_id, name, link = @basic_details
    lower_case_ids = get_lower_ids(get_value(page, 'Cause Numbers:'))
    county = get_value(page, 'County:')
    additional_info_array = []
    lower_case_ids.each do |lower_case_id|
      data_hash = {
        court_id: 405,
        case_id: case_id,
        lower_court_name:  "Arizona Superior Court in #{county} County",
        lower_case_id: lower_case_id,
        lower_judge_name: get_judge_name(page),
        data_source_url: "https://www.appeals2.az.gov/ODSPlus/#{link}"
      }
      data_hash = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      additional_info_array << data_hash
    end
    additional_info_array
  end

  def get_case_parties(page, run_id)
    case_id, name, link = @basic_details
    party_array = []
    type = ""
    get_table(page, "Party/Attorney Information").css('tr')[2..-1].each do |row|
      row.css('td').each_with_index do |each_row, index|
        if !each_row.search('p').text.empty?
          type =  each_row.search('p').text.squish
        else
          type = (each_row.text.strip.empty?) ? type :  each_row.text.strip.split("\r").last.squish
        end
        check = (each_row.search('p').text.empty?) ? 0 : 1
        each_row.search('p').map{|n| n.replace("\r\n\t__breaker\r\n\t")}
        values = each_row.text.split("\r\n\t").reject{|a| a.empty?}.map{|a| a.squish}.reject{|a| a.empty?}
        values = values.split("__breaker").reject{|s| s.count == 0}
        values.each do |value|
          data_hash={}
          if index.even?
            is_lawyer = 0
            data_hash[:party_law_firm] = nil
            check == 0 ? (type = data_hash[:party_type] = value[-1]) : data_hash[:party_type] = type
          else
            is_lawyer = 1
            data_hash[:party_law_firm] = value[-1]
            data_hash[:party_type] = "#{party_array[-1][:party_type].split("Attorney").first.squish} Attorney" 
          end
          data_hash[:court_id] = 405
          data_hash[:case_id] = case_id
          data_hash[:data_source_url] = "https://www.appeals2.az.gov/ODSPlus/#{link}"
          data_hash[:party_name] = value[0]
          data_hash[:is_lawyer] = is_lawyer
          data_hash = mark_empty_as_nil(data_hash)
          data_hash[:md5_hash] = create_md5_hash(data_hash)
          data_hash[:run_id] = run_id
          data_hash[:touched_run_id] = run_id
          party_array << data_hash
        end
      end
    end
    party_array
  end

  def get_relations(info_hash, pdf_hash)
    {
      court_id: 405,
      case_info_md5: info_hash,
      case_pdf_on_aws_md5: pdf_hash
    }
  end

  private

  def get_outer_info(html, case_link ,date)
    page = parse_nokogiri(html)
    row = page.css('div.divOATableCaption').select{|row| row.css('a')[0]['href'] == case_link}[0]
    name = row.css("i").text
    case_id = row.css('a').text.squish
    link = row.css('a')[0]['href']
    date  = Date.strptime(date,"%m/%d/%Y") rescue nil
    @basic_details = [case_id, name, link ,date]
  end

  def get_value(data, title) 
    data.css("tr th.thcurves").text.split("\r").reject{|e| e.exclude?"#{title}"}.join().split(":").last.squish rescue nil
  end

  def get_judge_name(page)
    data_lines = page.css("tr th.thcurves").text.split("\r").reject{|e| e.squish.empty?}[1..-1]
    rows = data_lines.reject{|s| s.include? ":"}.reject{|s| s.include? "*"}
    rows.count > 0 ? rows.last : nil
  end

  def date_conversion(value)
    begin
      DateTime.strptime(value, '%m/%d/%Y').to_date
    rescue
      nil
    end
  end

  def get_lower_ids(lower_case_ids)
    return [] if lower_case_ids == "" 
    lower_case_ids.split(',').flatten.map{|s| s.split("\;")}.flatten.map{|s| s.split('&')}.flatten.map{|s| s.split(" and ")}.flatten
  end

  def get_table(html, table_tag)
    html.css('table').select{|s| s.css('tr th b').text.include? table_tag}[0]
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value.to_s.squish}
  end
end
