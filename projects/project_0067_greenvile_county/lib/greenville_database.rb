# frozen_string_literal: true
require_relative '../lib/greenville_parser'

require_relative '../models/greenville_case_activities'
require_relative '../models/greenville_case_info'
require_relative '../models/greenville_case_judgement'
require_relative '../models/greenville_case_party'

require_relative '../models/greenville_runs'

class PutInDb < Hamster::Scraper

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

    run_id_class = RunId.new(GreenvilleRuns)
    @run_id = run_id_class.run_id

    @scrape_dev_name = 'Maxim G.'
    @last_scrape_date = Date.today.to_s
    @next_scrape_date =  (Date.today+1).to_s

    @update = update
    #array of existing in db case_id

    parse_all_file(year)
    #run_id_class.finish

  end

  DB_MODEL = {
    :info => GreenvilleCaseInfo, :activities => GreenvilleCaseActivities, :party => GreenvilleCaseParty, :judgement => GreenvilleCaseJudgement
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
      existing_cases_hash = {
        :info => existing_cases(:info, case_id_array), :party => existing_cases(:party, case_id_array),
        :activities => existing_cases(:activities, case_id_array), :judgement => existing_cases(:judgement, case_id_array)
      }

      array_files.each do |filename|
        html_doc = @peon.give(file: filename, subfolder: subfolder)
        #begin
          parse = GreenvilleParser.new(html_doc)
        # rescue => error
        #   p error
        #   File.open("#{storehouse}/proj67_parsing", "a") do |file|
        #     file.write("#{Date.today.to_s}| #{filename} : #{error.to_s} \n")
        #   end
        #   next
        # end



        @case_id = filename.split('.gz')[0]
        Hamster.logger.debug(@case_id)
        @data_source_url = "https://www2.greenvillecounty.org/SCJD/PublicIndex/?case_id=#{@case_id}&filled_date=#{parse.info['case_filed_date']}" # Cannot access via URL, so it's useless



        put_activities(parse.activities, existing_cases_hash[:activities])
        put_party(parse.party, parse.info, existing_cases_hash[:party])
        put_judgement(parse.judgements, parse.info, existing_cases_hash[:judgement])
        put_info(parse.info, existing_cases_hash[:info])

        @peon.move(file: filename, from: subfolder, to: subfolder)

      end
    end
  end

  def get_court(court_id)
    client = Mysql2::Client.new(Storage[host: :db01, db: :us_courts].except(:adapter).merge(symbolize_keys: true))
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

      # Take array of all case_id at #{month} and #{year}
      activerecord.where(court_id: @court[:court_id]).where(case_id:case_id_array).select(:case_id, :md5_hash).each do |line|
        existing_cases_hash[line.case_id] = line.md5_hash
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
    case_info = GreenvilleCaseInfo.new do |i|
      i.court_id = @court[:court_id]

      i.case_name = info[:case_name]
      i.case_id = info[:case_id]
      i.case_filed_date   = info['case_filed_date']
      i.case_description  = info['case_description']
      i.case_type         = info['case_type']
      i.disposition_or_status = info["disposition_or_status"]
      i.status_as_of_date = info['status_as_of_date']
      i.judge_name        = info['judge_name']

      i.data_source_url  = @data_source_url

      i.run_id = @run_id
      i.touched_run_id = @run_id
    end

    md5  = MD5Hash.new(table: :info)
    case_info.md5_hash = md5.generate(case_info.serializable_hash)
    if case_info.md5_hash.in?(existing_cases_hash.values)
      GreenvilleCaseInfo.where(md5_hash:case_info.md5_hash).update_all(touched_run_id:@run_id, deleted:0)
      return
    end

    GreenvilleCaseInfo.where(case_id:@case_id).where.not(md5_hash:case_info.md5_hash).update_all(deleted:1)

    begin
      case_info.save
    rescue => error
      Hamster.logger.error "INFO Error: #{error}"
      return
    end

  end


  def put_activities(activities, existing_cases_hash)
    activities.each do |activity|
      case_activities = GreenvilleCaseActivities.new do |i|
        i.court_id = @court[:court_id]
        i.case_id = activity[:case_id]

        i.activity_date = activity[:activity_date]
        i.activity_decs = activity[:activity_decs]
        i.activity_type = activity[:acitivity_type]
        i.activity_pdf  = activity[:activity_pdf]
        i.data_source_url = @data_source_url

        i.run_id = @run_id
        i.touched_run_id = @run_id
      end

      md5  = MD5Hash.new(table: :activities)
      case_activities.md5_hash = md5.generate(case_activities.serializable_hash)

      if case_activities.md5_hash.in?(existing_cases_hash.values)
        GreenvilleCaseActivities.where(md5_hash:case_activities.md5_hash).update_all(touched_run_id:@run_id, deleted:0)
        next
      end

      begin
        case_activities.save
      rescue => error
        Hamster.logger.error "Activities Error: #{error}"
        next
      end
    end

  end

  def put_party(parties, info, existing_cases_hash)
    parties.each do |party|
      case_party = GreenvilleCaseParty.new do |i|
        i.court_id =      @court[:court_id]
        i.case_id =       info['case_id']
        i.party_name =    party[:party_name]
        i.party_type =    party[:party_type]
        i.party_address = party[:party_address]
        i.party_city =    party[:party_city]
        i.party_state =   party[:party_state]
        i.party_zip =     party[:party_zip]
        i.is_lawyer =     party[:is_lawyer]

        i.data_source_url = @data_source_url

        i.run_id = @run_id
        i.touched_run_id = @run_id
      end

      md5  = MD5Hash.new(table: :party)
      case_party.md5_hash = md5.generate(case_party.serializable_hash)

      if case_party.md5_hash.in?(existing_cases_hash.values)
        GreenvilleCaseParty.where(md5_hash:case_party.md5_hash).update_all(touched_run_id:@run_id, deleted:0)
        next
      end

      begin
        case_party.save
      rescue => error
        Hamster.logger.error "PARTY Error: #{error}"
        next
      end
    end
  end


  def put_judgement(judgements, info, existing_cases_hash)
    judgements.each do |judgement|
      case_judgement = GreenvilleCaseJudgement.new do |i|

        i.court_id    = @court[:court_id]
        i.case_id     = info['case_id']
        i.case_type   = info['case_type']

        i.party_name      = judgement[:party_name]
        i.judgment_amount = judgement[:judgment_amount]
        i.judgment_date   = judgement[:judgment_date]
        i.fee_amount      = judgement[:fee_amount]

        i.data_source_url = @data_source_url
        i.touched_run_id = @run_id
        i.run_id = @run_id

      end

      md5  = MD5Hash.new(columns:%i[court_id case_id case_type party_name judgment_amount judgment_date fee_amount])
      case_judgement.md5_hash = md5.generate(case_judgement.serializable_hash)

      if case_judgement.md5_hash.in?(existing_cases_hash.values)
        GreenvilleCaseJudgement.where(md5_hash: case_judgement.md5_hash).update_all(touched_run_id:@run_id, deleted:0)
        next
      end


      begin
        case_judgement.save
      rescue => error
        Hamster.logger.error "judgement Error: #{error}"
        next
      end
    end

  end

end