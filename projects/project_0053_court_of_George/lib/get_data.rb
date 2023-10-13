#require 'RequestSite'
require 'nokogiri'
require 'date'
require_relative 'RequestSite'

require_relative '../models/us_courts_table'
require_relative '../models/us_case_info'
require_relative '../models/us_case_party'
require_relative '../models/us_case_lawyer'
require_relative '../models/us_case_activities'
require_relative '../models/us_case_runs'



class Parse < Hamster::Scraper

  def initialize
    @searchterms = ['S16', 'S17', 'S18', 'S19', 'S20', 'S21', 'S22', 'S23', 'S24']
    @searchterms = ['S']
    @scrape_dev_name = 'Maxim G'
    @court_id = 11#self.new_court
  end

  def manager
    run_id_classes = {
      :info => RunId.new(UsCaseInfoRuns),
      :party => RunId.new(UsCasePartyRuns),
      :activities => RunId.new(UsCaseActivitiesRuns),
    }
    @run_id = {
      :info => run_id_classes[:info].run_id,
      :party => run_id_classes[:party].run_id,
      :activities => run_id_classes[:activities].run_id,
    }
    term = 20
    loop do
      searchterm = "S#{term}"
      log "Start for #{searchterm}" ,'red'
      cases_on_page = self.get_list_casenumber(searchterm)
      break if cases_on_page.empty?
      existed_cases = []
      UsCaseInfo.where(court_id: @court_id).where(deleted:0).where("case_id like '#{searchterm}%'").select(:case_id).each do |line|
        existed_cases.push(line.case_id)
      end
      cases_on_page.each do |case_number|
        next if existed_cases.include?(case_number)
        case_data = GetCase.new(case_number)
        info = case_data.get_case_info
        lawyer = case_data.get_case_lawyer
        parties = lawyer[:parties]
        proceedings = case_data.get_case_activities
        begin
          self.put_data_in_db(info, lawyer, parties, proceedings)
        rescue => e
          p e
          UsCaseInfo.where(case_id:case_number).destroy_all
          UsCaseActivities.where(case_id:case_number).destroy_all
          UsCaseParty.where(case_id:case_number).destroy_all
          exit 0
        end
      end
      log "End for #{searchterm}" ,'red'

      UsCaseInfo.where(court_id:@court_id).where(deleted:0).where(case_id:existed_cases).update_all(touched_run_id:@run_id[:info])
      UsCaseActivities.where(court_id:@court_id).where(deleted:0).where(case_id:existed_cases).update_all(touched_run_id:@run_id[:activities])
      UsCaseParty.where(court_id:@court_id).where(deleted:0).where(case_id:existed_cases).update_all(touched_run_id:@run_id[:party])

      term+=1
    end

  end



  def get_all_case_numbers
    all_case_number = Array.new()

    @searchterms.each do |searchterm|
      all_case_number.concat(self.get_list_casenumber(searchterm)) #TODO: change loop on one url: https://scweb.gasupreme.org:8088/results_docket.php?searchterm=%s&submit=Search
    end

    all_case_number
  end


  def start
    run


    all_case_number = self.get_all_case_numbers

    old_case_numbers = []
    UsCaseInfo.where(court_id: @court_id).where(deleted:0).select(:case_id).each do |line|
      old_case_numbers.push(line.case_id)
    end


    all_case_number.each do |case_number|
      next if old_case_numbers.include?(case_number)
      case_data = GetCase.new(case_number)
      info = case_data.get_case_info
      lawyer = case_data.get_case_lawyer
      parties = lawyer[:parties]
      proceedings = case_data.get_case_activities
      begin
        self.put_data_in_db(info, lawyer, parties, proceedings)
      rescue => e
        p e
        UsCaseInfo.where(case_id:case_number).destroy_all
        UsCaseActivities.where(case_id:case_number).destroy_all
        UsCaseParty.where(case_number:case_number).destroy_all
        exit 0
      end

    end
  end


  def new_court
    if UsCourtsTable.find_by(court_name: @court[:court_name])
      return UsCourtsTable.where(court_name: @court[:court_name]).first.id
    end

    court = UsCourtsTable.new do |c|
      c.court_name = @court[:court_name]
      c.court_state = @court[:court_state]
      c.court_type = @court[:court_type]
      c.court_sub_type = @court[:court_sub_type]

      c.scrape_dev_name = @scrape_dev_name
      c.data_source_url = 'https://scweb.gasupreme.org:8088/'

      c.scrape_frequency = 'daily'
      c.last_scrape_date = Date.today
      c.next_scrape_date = Date.today+1
      c.expected_scrape_frequency = 'daily'


    end
    court.save
    UsCourtsTable.where(court_name: @court[:court_name]).first.id
  end


  # making md5 string from values from object active_record
  def make_md5(act_record)
    all_values_str=''
    act_record.serializable_hash.each_value.each do |value|
      all_values_str = all_values_str + value.to_s
    end

    Digest::MD5.hexdigest all_values_str
  end


  def put_data_in_db(info, lawyer, parties, proceedings)

    case_info = UsCaseInfo.new do |i|
      i.court_id = @court_id
      i.case_name = info['case_name']
      i.case_id = info['case_id']
      i.case_filed_date = info['case_filed_date']
      i.case_description = info['case_description']
      i.case_type = info['case_type']
      i.disposition_or_status = info['disposition_or_status']
      i.status_as_of_date = info['status_as_of_date']
      i.judge_name = nil
      i.run_id = @run_id[:info]
      i.touched_run_id = @run_id[:info]

      i.created_by = @scrape_dev_name
      i.data_source_url = "https://scweb.gasupreme.org:8088/results_one_record.php?caseNumber=%s" %info['case_id']

    end
    #case_info.md5_hash = make_md5(case_info)
    md5  = PacerMD5.new(data: case_info.serializable_hash, table: 'info')
    case_info.md5_hash = md5.hash
    case_info.save

    proceedings.each do |activity|
      case_activities = UsCaseActivities.new do |i|
        i.court_id = @court_id
        i.case_id = info['case_id']

        if activity[:activity_date]!=""
          i.activity_date = Date.parse(activity[:activity_date])
        else
          i.activity_date = ''
        end

        i.activity_decs = activity[:activity_decs]
        i.activity_type = activity[:activity_type]

        i.run_id = @run_id[:activities]
        i.touched_run_id = @run_id[:activities]
        i.created_by = @scrape_dev_name
        i.data_source_url = "https://scweb.gasupreme.org:8088/results_one_record.php?caseNumber=%s" %info['case_id']
      end
      #case_activities.md5_hash = make_md5(case_activities)
      md5  = PacerMD5.new(data: case_activities.serializable_hash, table: 'activities')
      md5_hash = md5.hash
      existed_activity_md5_hash = UsCaseActivities.find_by(md5_hash:md5_hash)
      unless existed_activity_md5_hash.nil?
        existed_activity_md5_hash.update(touched_run_id:@run_id[:activities], deleted:0)
        next
      end

      case_activities.md5_hash = md5_hash
      case_activities.save
    end

    parties.each do |party|
      case_party = UsCaseParty.new do |i|
        i.court_id = @court_id
        i.case_id = info['case_id']
        i.is_lawyer = 0
        i.party_name = party[:party_name].strip
        i.party_type = party[:party_type].strip
        i.party_address = party[:party_address].strip
        i.party_city = party[:party_city]
        i.party_state = party[:party_state]
        i.party_zip = party[:party_zip]
        i.party_law_firm = party[:law_firm]

        i.run_id = @run_id[:party]
        i.touched_run_id = @run_id[:party]

        i.created_by = @scrape_dev_name
        i.data_source_url = "https://scweb.gasupreme.org:8088/results_one_record.php?caseNumber=%s" %info['case_id']

      end
      md5  = PacerMD5.new(data: case_party.serializable_hash, table: 'party')

      md5_hash = md5.hash
      existed_party_md5_hash = UsCaseParty.find_by(md5_hash:md5_hash)
      unless existed_party_md5_hash.nil?
        existed_party_md5_hash.update(touched_run_id:@run_id[:party], deleted:0)
        next
      end

      case_party.md5_hash = md5_hash
      case_party.save
    end

  end


  def get_list_casenumber(searchterm='S16')
    url_get = "https://scweb.gasupreme.org:8088/results_docket.php?searchterm=%s&submit=Search" %searchterm

    #resp = connect_to(url_get)

    #html_site = resp.body
    # else
    cobble = Dasher.new(:using=>:cobble, :redirect=>true)
    html_site = cobble.get(url_get)
    # end

    case_number_array = []
    doc = Nokogiri::HTML(html_site)

    doc.css('table td b').each do |link|
      if link.content[0..searchterm.length].strip==searchterm
        case_number_array.push(link.content.strip)
      end
    end
    case_number_array
  end
end



class GetCase < Hamster::Scraper

  def initialize(caseNumber)
    @caseNumber=caseNumber
    @doc = self.get_one_case(@caseNumber)
    @section_number = self.divide_data(@doc)
    @good_symbols = 'A-Za-z0-9,\#\.\-_@ '
    @proceedings_column_names = ['Date', 'Filings & Motions', 'Date', 'Orders']
  end

  def get_one_case(caseNumber=@caseNumber)
    url_get = "https://scweb.gasupreme.org:8088/results_one_record.php?caseNumber=%s" %caseNumber

    cobble = Dasher.new(:using=>:cobble, :redirect=>true)
    html_site = cobble.get(url_get)

    doc = Nokogiri::HTML(html_site)
    doc
  end

  def divide_data(doc=@doc)
    section_number = Hash.new
    o=0
    doc.css('table').each do |line|
      case line.css('tr, b')[0].content.strip
      when 'Case Number:'
        section_number['Info'] = o
      when 'Attorneys'
        section_number['Attorneys'] = o
      when 'Disposition'
        section_number['Disposition'] = o
      when 'Proceedings'
        section_number['Proceedings'] = o
      end
      o=o+1
    end
    return section_number
  end


  def get_case_info(doc=@doc, section_number=@section_number)
    info_hash = {'Case Number:' => 'case_id', 'Description:' => 'case_description', 'Docket Date:' => 'case_filed_date',
                 'Style:' => 'case_name', 'Status:' => 'status_as_of_date'}
    info_hash_new = Hash.new()
    table = doc.css('table')[0]
    table.css('tr').each do |line|
      if info_hash.include?(line.css('td')[0].content.strip)
        info_hash_new[info_hash[line.css('td')[0].content.strip]] = line.css('td')[1].content.strip
      end
    end
    info_hash_new['case_type'] = info_hash_new['case_description'].split('-')[0].strip

    info_hash_new['case_filed_date'] = Date.parse(info_hash_new['case_filed_date']) unless info_hash_new['case_filed_date'].nil?

    table_number = section_number['Disposition']
    if table_number+1!=section_number['Attorneys']
      disposition = ''
      disp_content = doc.css('table')[table_number+1]
      disp_content.css('b').each do |c|
        disposition += c.content
      end

      #disp_content.content.gsub()
      info_hash_new['activity_date_disposition'] = /Disposition Date: [0-9A-Za-z.,:()\s]{1,}/.match(disp_content)[0].gsub('Disposition Date: ', '').strip
      info_hash_new['disposition_or_status'] = disposition.strip
    end

    info_hash_new
  end


  def get_case_lawyer(doc=@doc, section_number=@section_number)
    lawyer_array = []
    parties = []
    doc.css('table')[section_number['Attorneys']+1..].each do |attorney|
      columns = attorney.css('td')

      new_lawyer = {
        party_name: columns[0].content.split(' ').map! {|w| w.capitalize}.join(' '),
        party_type: columns[1].content,
        #party_address: columns[2].content,
      }

      law_firm_address = columns[2]
      if !law_firm_address.nil?
        #law_firm_address.css('br').each { |br| br.replace("\n") }
        new_lawyer[:party_address] = law_firm_address.content.strip
        divided_address = new_lawyer[:party_address].split("\n")

        new_lawyer[:law_firm] = divided_address[0] if divided_address.length>2
        matched = divided_address[-1].strip.match(/(\w*)\, (\w*) (\d-?\d*)/)

        if !matched.nil?
          new_lawyer[:party_city] = matched[1]
          new_lawyer[:party_state] = matched[2]
          new_lawyer[:party_zip] = matched[3]
        end
      end

      parties.push(new_lawyer)

      case columns[1].content.strip
      when 'Appellant'
        lawyer_array.push({'plantiff_or_defendant'=>'p'})
      when 'Appellee'
        lawyer_array.push({'plantiff_or_defendant'=>'d'})
      else
        lawyer_array.push({})
      end
      lawyer_array[-1]['lawyer'] = columns[0].content.strip
      lawyer_array[-1]['firm'] = columns[2].content.strip.split("\n")[0].strip
    end
    hash_for_db = {}
    # lawyer_array.each do |lawyer|
    #   if lawyer['plantiff_or_defendant'] == 'p' and !hash_for_db.include?('defendant_lawyer')
    #     hash_for_db['defendant_lawyer'] = lawyer['lawyer']#.gsub(/[^#{@good_symbols}]/, '')
    #     hash_for_db['defendant_lawyer_firm'] = lawyer['firm']#.gsub(/[^#{@good_symbols}]/, '')
    #   elsif lawyer['plantiff_or_defendant'] == 'd' and !hash_for_db.include?('plantiff_lawyer')
    #     hash_for_db['plantiff_lawyer'] = lawyer['lawyer']#.gsub(/[^#{@good_symbols}]/, '')
    #     hash_for_db['plantiff_lawyer_firm'] = lawyer['firm']#.gsub(/[^#{@good_symbols}]/, '')
    #   elsif hash_for_db.include?('plantiff_lawyer') and hash_for_db.include?('defendant_lawyer')
    #     break
    #   end
    # end
    hash_for_db[:parties] = parties
    hash_for_db
  end


  def get_case_party(doc=@doc, section_number=@section_number)
    nil
  end


  def get_case_activities(doc=@doc, section_number=@section_number)
    proceedings = Array.new()
    proc_table_start = section_number['Proceedings']
    proc_table_end = section_number['Disposition']
    doc.css('table')[proc_table_start].css('tr')[1].css('td').each do |column_name|
      if !@proceedings_column_names.include?(column_name.content.strip)
        puts "Error '#{column_name.content.strip}' is not in list"
      end
    end

    doc.css('table')[proc_table_start+1..proc_table_end-1].each do |proceeding|
      columns = proceeding.css('td')
      proceedings.push({})
      proceedings[-1][:activity_date] = columns[0].content.strip
      proceedings[-1][:activity_decs] = columns[1].content.strip#.gsub(/[^#{@good_symbols}]/, '')
      proceedings[-1][:activity_type] = /(^([A-Z]{2,}(\W|$))*)/.match(proceedings[-1][:activity_decs]).to_s.strip
      proceedings[-1][:orders] = columns[3].content.strip
    end

    # if proceedings.length !=0
    #   return proceedings[0]
    # else
    #   proceedings = {:activity_date=>"", :activity_decs=>""}
    #   return proceedings
    # end
    proceedings
  end


end
