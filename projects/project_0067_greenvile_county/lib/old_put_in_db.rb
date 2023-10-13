# frozen_string_literal: true
require_relative '../lib/parser'

require_relative '../models/us_case_info'
require_relative '../models/us_case_party'
require_relative '../models/us_case_lawyer'
require_relative '../models/us_case_activities'

class OLDPutInDb < Hamster::Scraper

  def initialize(year, update=0)
    super
    scrape_year = year
    @subfolder = "#{scrape_year}"

    @peon = Peon.new(storehouse)


    @court = {
      :court_id => 32,
      :court_name => 'Greenville County Courts',
      :court_state => 'South Carolina',
      :court_type => 'Greenville County Courts',
      :court_sub_type => 'Circuit Court'
    }

    @scrape_dev_name = 'Maxim Gushchin'
    @scrape_frequency = 'daily'
    @pl_gather_task_id = 67
    @last_scrape_date = Date.today.to_s
    @next_scrape_date =  (Date.today+1).to_s

    @update = update
    get_court(32)

    #array of existing in db case_id



    parse_all_file(year)

  end

  DB_MODEL = {
    :info => UsCaseInfo, :activities => UsCaseActivities, :party => UsCaseParty, :lawyer => UsCaseLawyer
  }

  def parse_all_file(year)
    (1..12).to_a.each do |month|
      subfolder = "#{year}/#{month}/"
      subfolder += 'update/' if @update!=0
      array_files = @peon.give_list(subfolder:subfolder)
      #old_case_id = { :info => case_id_in_db(:info, year, month) } if !array_files.empty?
      #, :activities => case_id_in_db(:activities, year),
      #:party => case_id_in_db(:party, year), :lawyer => case_id_in_db(:lawyer, year) }
      case_id_array = array_files.map { |filename| filename.split('.gz')[0] }
      existing_cases_hash = { :info => existing_cases(:info, case_id_array), :party => existing_cases(:party, case_id_array),
                              :activities => existing_cases(:activities, case_id_array), :lawyer => existing_cases(:lawyer, case_id_array)
      }
      array_files.each do |filename|
        html_doc = @peon.give(file: filename, subfolder: subfolder)
        begin
          parse = Parser.new(html_doc)
        rescue => error
          File.open("#{storehouse}logs/proj67_parsing", "a") do |file|
            file.write("#{Date.today.to_s}| #{filename} : #{error.to_s} \n")
          end
          next
        end



        case_id = filename.split('.gz')[0]
        @data_source_url = "https://www2.greenvillecounty.org/SCJD/PublicIndex/CaseDetails.aspx?County=23&CourtAgency=23102&Casenum=#{case_id}&CaseType=V&filled_date=#{parse.info['case_filed_date']}" # Cannot access via URL, so it's useless
        #if !old_case_id[:info].include?(case_id)
        put_activities(parse.activities, existing_cases_hash[:activities])
        put_party(parse.party, parse.info, existing_cases_hash[:party])
        put_lawyer(parse.lawyer, parse.info, existing_cases_hash[:lawyer])
        put_info(parse.info, existing_cases_hash[:info])
        #end

        # if !old_case_id[:activities].include?(case_id)
        #
        # end
        # if !old_case_id[:party].include?(case_id)
        #
        # end
        # if !old_case_id[:lawyer].include?(case_id)
        #
        # end
        @peon.move(file: filename, from: subfolder, to: subfolder)

      end
    end
  end

  def get_court(court_id)
    client = Mysql2::Client.new(Storage[host: :db01, db: :usa_raw].except(:adapter).merge(symbolize_keys: true))
    query = "SELECT court_id,court_name,court_state,court_type,court_sub_type FROM us_courts_table WHERE court_id=#{court_id}"
    statement = client.prepare(query)
    result = statement.execute
    if result.first
      @court = result.first
    else
      query = "INSERT INTO us_courts_table (court_id,court_name,court_state,court_type,court_sub_type) VALUES
              (#{@court[:court_id]}, '#{@court[:court_name]}', '#{@court[:court_state]}', '#{@court[:court_type]}', '#{@court[:court_sub_type]}');"
      client.query(query)
    end
    client.close
  end

  def case_id_in_db(table, year, month)
    activerecord = DB_MODEL[table.to_sym]
    old_case_numbers = []
    date_from = "#{year}-#{month.to_s.rjust(2, '0')}-01"
    if month<12
      date_to = "#{year}-#{(month+1).to_s.rjust(2, '0')}-01"
    elsif month==12
      date_to = "#{year+1}-01-01"
    end


    if table.to_sym==:info
      # Take array of all case_id at #{month} and #{year}
      activerecord.where(court_id: @court[:court_id]).where("case_filed_date>='#{date_from}' AND case_filed_date<'#{date_to}'").select(:case_id).each do |line|
        old_case_numbers.push(line.case_id)
      end
      # elsif [:party, :lawyer].include?(table.to_sym)
      #   activerecord.where(court_id: @court[:court_id]).select(:case_number).each do |line|
      #     old_case_numbers.push(line.case_number)
      #   end
      # else
      #   activerecord.where(court_id: @court[:court_id]).select(:case_id).each do |line|
      #     old_case_numbers.push(line.case_id)
      #   end
    end
    old_case_numbers
  end

  def existing_cases(table, case_id_array)
    activerecord = DB_MODEL[table.to_sym]

    existing_cases_hash = {}
    if [:info, :activities].include?(table.to_sym)
      # Take array of all case_id at #{month} and #{year}
      activerecord.where(court_id: @court[:court_id]).where(case_id:case_id_array).select(:case_id, :md5_hash).each do |line|
        existing_cases_hash[line.case_id] = line.md5_hash
      end
    elsif [:party, :lawyer].include?(table.to_sym)
      activerecord.where(court_id: @court[:court_id]).where(case_number:case_id_array).select(:case_number, :md5_hash).each do |line|
        existing_cases_hash[line.case_number] = line.md5_hash
      end
    end

    existing_cases_hash #, existing_md5_hash
  end



  #________SAVE TO DB by ACTIVERECORD________

  def put_info(info, existing_cases_hash)
    # the_case = UsCaseInfo.where(case_id:info[:case_id],disposition_or_status:'').first
    # if the_case and info["disposition_or_status"]!=''
    #   the_case.destroy
    # elsif the_case
    #   return
    # end
    case_info = UsCaseInfo.new do |i|
      i.court_id = @court[:court_id]
      i.court_name = @court[:court_name]
      i.court_state = @court[:court_state]
      i.court_type = @court[:court_type]
      i.case_name = info[:case_name]
      i.case_id = info[:case_id]
      i.case_filed_date = info['case_filed_date']
      i.case_description = info['case_description'] || ''
      i.case_type = info['case_type'] || ''
      i.disposition_or_status = info["disposition_or_status"] || ''
      i.status_as_of_date = info['status_as_of_date']
      i.judge_name = info['judge_name']

      i.next_scrape_date = @next_scrape_date
      i.last_scrape_date = @last_scrape_date
      i.scrape_dev_name = @scrape_dev_name
      i.data_source_url = @data_source_url
      i.scrape_frequency = @scrape_frequency
      i.expected_scrape_frequency = @scrape_frequency
      i.pl_gather_task_id = @pl_gather_task_id
    end
    md5  = PacerMD5.new(data: case_info.serializable_hash, table: 'info_root')
    case_info.md5_hash = md5.hash

    return if case_info.md5_hash.in?(existing_cases_hash.values)

    if existing_cases_hash.keys.include?(case_info.case_id)
      UsCaseInfo.where(court_id:@court[:court_id]).where(case_id:info[:case_id]).destroy_all
    end

    begin
      case_info.save
    rescue => error
      p error
      File.open("#{storehouse}logs/proj67_db_info", "a") do |file|
        file.write("#{Date.today.to_s}| #{error.to_s} \n")
      end
      return
    end

  end

  def put_activities(activities, existing_cases_hash)
    activities.each do |activity|
      case_activities = UsCaseActivities.new do |i|
        i.court_id = @court[:court_id]
        i.case_id = activity['case_id']
        i.activity_date = activity["activity_date"]
        # if proceedings[:activity_date]!=""
        #   i.activity_date = Date.parse(proceedings[:activity_date])
        # elsif info['activity_date_disposition']
        #   i.activity_date = Date.parse(info['activity_date_disposition'])
        # else
        #   i.activity_date = ''
        # end

        i.activity_decs = activity["activity_decs"]
        i.activity_type = ''
        i.activity_pdf = activity["activity_pdf"]

        i.next_scrape_date = @next_scrape_date
        i.last_scrape_date = @last_scrape_date
        i.scrape_dev_name = @scrape_dev_name
        i.data_source_url = @data_source_url
        i.scrape_frequency = @scrape_frequency
        i.expected_scrape_frequency = @scrape_frequency
        i.pl_gather_task_id = @pl_gather_task_id
      end
      md5  = PacerMD5.new(data: case_activities.serializable_hash, table: 'activities_root')
      case_activities.md5_hash = md5.hash
      return if case_activities.md5_hash.in?(existing_cases_hash.values)
      begin
        case_activities.save
      rescue => error
        File.open("#{storehouse}logs/proj67_db_activities", "a") do |file|
          file.write("#{Date.today.to_s}| #{error.to_s} \n")
        end
        next
      end
    end
  end

  def put_party(parties, info, existing_cases_hash)
    parties.each do |party|
      case_party = UsCaseParty.new do |i|
        i.court_id = @court[:court_id]
        i.case_number = info['case_id']
        i.party_name = party[:party_name]
        i.party_type = party[:party_type]
        i.party_address = party[:party_address]
        i.party_city = party[:party_city]
        i.party_state = party[:party_state]
        i.party_zip = party[:party_zip]
        i.is_lawyer = 0
        i.party_description = ''
        i.law_firm = ''

        i.next_scrape_date = @next_scrape_date
        i.last_scrape_date = @last_scrape_date
        i.scrape_dev_name = @scrape_dev_name
        i.data_source_url = @data_source_url
        i.scrape_frequency = @scrape_frequency
        i.expected_scrape_frequency = @scrape_frequency
        i.pl_gather_task_id = @pl_gather_task_id
      end
      md5  = PacerMD5.new(data: case_party.serializable_hash, table: 'party_root')
      case_party.md5_hash = md5.hash

      return if case_party.md5_hash.in?(existing_cases_hash.values)

      begin
        case_party.save
      rescue => error
        File.open("#{storehouse}logs/proj67_db_party", "a") do |file|
          file.write("#{Date.today.to_s}| #{error.to_s} \n")
        end
        next
      end
    end
  end

  def put_lawyer(lawyers, info, existing_cases_hash)
    lawyers.each do |lawyer|
      case_lawyer = UsCaseLawyer.new do |i|
        i.court_id = @court[:court_id]
        i.case_number = info['case_id']
        i.defendant_lawyer = lawyer[:defendant_lawyer] || ''
        i.defendant_lawyer_firm = lawyer[:defendant_lawyer_firm] || ''
        i.plantiff_lawyer = lawyer[:plantiff_lawyer] || ''
        i.plantiff_lawyer_firm = lawyer[:plantiff_lawyer_firm] || ''

        i.next_scrape_date = @next_scrape_date
        i.last_scrape_date = @last_scrape_date
        i.scrape_dev_name = @scrape_dev_name
        i.data_source_url = @data_source_url
        i.scrape_frequency = @scrape_frequency
        i.expected_scrape_frequency = @scrape_frequency
        i.pl_gather_task_id = @pl_gather_task_id
      end
      md5  = PacerMD5.new(data: case_lawyer.serializable_hash, table: 'lawyer_root')
      case_lawyer.md5_hash = md5.hash

      return if case_lawyer.md5_hash.in?(existing_cases_hash.values)

      begin
        case_lawyer.save
      rescue => error
        File.open("#{storehouse}logs/proj67_db_lawyer", "a") do |file|
          file.write("#{Date.today.to_s}| #{error.to_s} \n")
        end
        next
      end
    end
  end

end