# frozen_string_literal: true

class Parser < Hamster::Parser
  COURT_ID = '89'

  def initialize_values(page)
    @html = Nokogiri::HTML page
  end

  def total_pages page
    initialize_values(page.body)
    @html.css("#cphNoMargin_cphNoMargin_OptionsBar1_ItemList option").last.values.first.to_i
  end

  def parsing(page, run_id)
    initialize_values(page)
    @case_info = [] 
    @case_party = []
    @case_activities = []
    @table_body =  @html.css(".ig_ElectricBlueItem")
    no_of_records =  @html.css(".ig_ElectricBlueItem tr").count
    (1..no_of_records).each do |row| 
        extract_table_data(row, run_id)
    end
    [@case_info.uniq, @case_party.uniq, @case_activities.uniq]
  end

  def extract_table_data (row, run_id)
    td = @table_body.css("tr[#{row}] td")
    case_info(td[3].text, td[6].text, td[7].text, run_id )
    case_activities(td[8].text, td[9].text, td[3].text, run_id)
    case_party(td[10].text, td[11].text, td[3].text, run_id)
  end

  def case_info (case_no, case_date, case_type, run_id)
    data_hash = {} 
    data_hash[:court_id] = COURT_ID
    data_hash[:case_id] = case_no
    data_hash[:case_filed_date] = Date.strptime(case_date, '%m/%d/%Y')
    data_hash[:case_type] = case_type
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:data_source_url] = "https://jeffersontxclerk.manatron.com/Court/SearchDetail.aspx"
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:touched_run_id] = run_id
    data_hash[:run_id] = run_id
    @case_info << data_hash
  end

  def case_party (partytype, partyname, case_no, run_id) 
    data_hash = {} 
    data_hash[:court_id] = COURT_ID
    data_hash[:case_id] = case_no
    data_hash[:is_lawyer] = 0
    data_hash[:party_name] = partyname
    data_hash[:party_type] = partytype
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:data_source_url] = "https://jeffersontxclerk.manatron.com/Court/SearchDetail.aspx"
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:touched_run_id] = run_id
    data_hash[:run_id] = run_id
    @case_party << data_hash
  end

  def case_activities (activitytype, activitydate, case_no, run_id)
    data_hash = {} 
    data_hash[:court_id] = COURT_ID
    data_hash[:case_id] = case_no
    data_hash[:activity_type] = activitytype
    data_hash[:activity_date] = Date.strptime(activitydate, '%m/%d/%Y')
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:data_source_url] = "https://jeffersontxclerk.manatron.com/Court/SearchDetail.aspx"
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:touched_run_id] = run_id
    data_hash[:run_id] = run_id
    @case_activities << data_hash
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| value.to_s.empty? || value == 'null' ? nil : value }
  end

  
end
