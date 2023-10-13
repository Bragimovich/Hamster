# frozen_string_literal: true

require_relative '../models/ks_ac_case_info'
require_relative '../models/ks_ac_case_party'
require_relative '../models/ks_ac_case_activities'
require_relative '../models/ks_ac_case_runs'

class KsAcCaseParser < Hamster::Parser

  SOURCE = 'https://pittsreporting.kscourts.org'
  COURT_ID = 430
  CHUNK = 5000
  QUANT = 100

  def initialize(*_)
    super
    @run_id = nil
    @stored_cases_md5, @stored_parties_md5, @stored_activities_md5 = [], [], []
    @unchanged_cases_md5, @unchanged_parties_md5, @unchanged_activities_md5 = [], [], []
  end

  def start(update: false)
    send_to_slack message: "project_0390 - store started"
    log_store_started

    collect_stored_md5_data unless update
    store_index_cases
    update_touched_deleted unless update

    log_store_finished
    send_to_slack message: "project_0390 - store finished"
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack message: "project_0390 start:\n#{e.inspect}"
  end

  private

  def collect_stored_md5_data
    @stored_cases_md5 = collect_stored_md5(KsAcCaseInfo)
    @stored_parties_md5 = collect_stored_md5(KsAcCaseParty)
    @stored_activities_md5 = collect_stored_md5(KsAcCaseActivities)
  end

  def store_index_cases
    idx_file_name = "#{@run_id.to_s.rjust(4, "0")}_index"
    idx_file_content = peon.give(file: idx_file_name)
    store_cases(idx_file_content)
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack message: "project_0390 store_index_cases:\n#{e.inspect}"
  end

  def store_cases(file_content)
    @cases_folder = "#{@run_id.to_s.rjust(4, "0")}_cases"
    downloaded_cases = peon.give_list(subfolder: @cases_folder).to_set
    cases = Nokogiri::HTML(file_content).at('.body-content table').css('tr')
    cases.each_slice(QUANT) do |collection|
      collection.each do |row|
        next if row.at('a').blank?
        case_link = SOURCE + row.at('a')['href']
        case_id = row.at('a').text.strip
        case_caption = row.css('td')[2].text

        next unless downloaded_cases.include? "#{case_id}_info_n_activities.gz"
        store_case(case_link, case_id, case_caption)
      end
    end
  end

  def store_case(case_link, case_id, case_caption)
    info_file_name = "#{case_id}_info_n_activities"
    file_content = peon.give(subfolder: @cases_folder, file: info_file_name)
    case_doc = Nokogiri::HTML(file_content)

    store_info(case_doc, case_link, case_id, case_caption)
    store_activities(case_doc, case_link, case_id)
    store_case_parties(case_id)
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack message: "project_0390 store_case:\n#{case_id}\n#{e.inspect}"
  end

  def store_info(case_doc, case_link, case_id, case_caption)
    case_name = case_caption.split.join(' ')
    case_raw_info = case_doc.at('.body-content').css('.row')
    rec = {}
    case_raw_info.each do |row|
      # rec[row.at('.col-3 label')&.attr('for')&.strip] = row.at('.col-9 label')&.text&.strip.presence
      rec[row.at('.col-3')&.text&.strip] = row.at('.col-9')&.text&.strip.presence
    end

    case_info = {
      court_id: COURT_ID,
      case_id: case_id,
      case_caption: case_caption,
      case_name: case_name, # rec["Case Caption"]
      case_filed_date: Date.strptime(rec["Date Docketed"], '%d-%b-%y'),
      case_type: rec["Case Type"],
      case_description: rec["Case Sub-Type"],
      data_source_url: case_link
    }
    case_info[:md5_hash] = calc_md5_hash(case_info)
    case_info[:run_id] = @run_id
    case_info[:touched_run_id] = @run_id

    #### @stored_cases_md5 is empty when @update == true
    if @stored_cases_md5.include? case_info[:md5_hash]
      @unchanged_cases_md5.push(case_info[:md5_hash])
    else
      store(case_info, KsAcCaseInfo)
    end
  end

  def store_activities(case_doc, link, case_id)
    new_activities = []
    dockets = case_doc.at('.body-content table').css('tr')
    dockets.each do |docket|
      next if docket.parent.name == 'thead'

      case_docket = {
        court_id: COURT_ID,
        case_id: case_id,
        activity_date: Date.strptime(docket.at('td').text.strip, '%d-%b-%y'),
        activity_desc: docket.css('td')[1].text.split(' / ', 2)[1].strip.presence,
        activity_type: docket.css('td')[1].text.split(' / ', 2)[0].strip.presence,
        data_source_url: link
      }
      case_docket[:md5_hash] = calc_md5_hash(case_docket)
      case_docket[:run_id] = @run_id
      case_docket[:touched_run_id] = @run_id

      #### @stored_activities_md5 is empty when @update == true
      if @stored_activities_md5.include? case_docket[:md5_hash]
        @unchanged_activities_md5.push(case_docket[:md5_hash])
      else
        new_activities.push(case_docket)
      end
    end
    store_all(new_activities, KsAcCaseActivities)
  end

  def store_case_parties(case_id)
    parties_file_name = "#{case_id}_parties"
    file_content = peon.give(subfolder: @cases_folder, file: parties_file_name)
    parties = Nokogiri::HTML(file_content).at('.body-content table')&.css('tr')
    return if parties.nil?
    new_parties = []
    parties.each do |party|
      next if party.parent.name == 'thead'
      party_type = party.css('td')[1].text.strip.presence
      party_link = party.at('a')['href']
      participant = parse_participant(case_id, party_type, party_link)
      new_parties.push(participant) unless participant.nil?
    end
    store_all(new_parties, KsAcCaseParty)
  end

  def parse_participant(case_id, party_type, party_link)
    litigantID = party_link.match(/(litigantID=)(\d+)(&)/)[2]
    party_file_name = "#{case_id}_party_#{litigantID}"
    party_folder = "#{@cases_folder}/#{case_id}"
    file_content = peon.give(subfolder: party_folder, file: party_file_name)
    records = Nokogiri::HTML(file_content).at('.body-content table').css('tr')
    rec = {}
    records.each do |record|
      next if record.parent.name == 'thead'
      col = record.css('td')
      rec[col[0].at('strong')&.text&.strip] = col[1]&.text&.strip
    end
    all, city, state, zip = *rec["City, State Zip"].match(/((?:[A-Z]+\s?)+)*\s([A-Z]{2})\s(\d{5}-?\d{4}?)/)

    case_party = {
      court_id: COURT_ID,
      case_id: case_id,
      is_lawyer: 0,
      party_name: rec["Name"],
      party_type: party_type,
      party_law_firm: rec["Firm Name"],
      party_address: [rec["Address 1"], rec["Address 2"]].compact_blank.join(', '),
      party_city: city,
      party_state: state,
      party_zip: zip,
      party_description: rec["Telephone/Ext."],
      data_source_url: SOURCE + party_link
    }
    case_party[:md5_hash] = calc_md5_hash(case_party)
    case_party[:run_id] = @run_id
    case_party[:touched_run_id] = @run_id

    #### @stored_parties_md5 is empty when @update == true
    if @stored_parties_md5.include? case_party[:md5_hash]
      @unchanged_parties_md5.push(case_party[:md5_hash])
      return nil
    end

    case_party
  end

  def store(record, model)
    model.insert record
  end

  def store_all(records, model)
    records.each_slice(CHUNK) do |records_chunk|
      model.insert_all(records_chunk)
    end
  end

  def update_touched_deleted
    update_touched_run_id(KsAcCaseInfo, @unchanged_cases_md5)
    update_deleted(KsAcCaseInfo)

    update_touched_run_id(KsAcCaseParty, @unchanged_parties_md5)
    update_deleted(KsAcCaseParty)

    update_touched_run_id(KsAcCaseActivities, @unchanged_activities_md5)
    update_deleted(KsAcCaseActivities)
  end

  def update_touched_run_id(model, unchanged_md5)
    unchanged_md5.each_slice(CHUNK) do |md5_chunk|
      model.where(md5_hash: md5_chunk).update_all(touched_run_id: @run_id)
    end
  end

  def update_deleted(model)
    model.where(deleted: 0).where.not(touched_run_id: @run_id).update_all "deleted = 1"
  end

  def collect_stored_md5(model)
    model.where(deleted: 0).pluck(:md5_hash).to_set
  end

  def list_saved_cases
    KsAcCaseInfo.where(deleted: 0).pluck(:case_id).to_set
  end

  def calc_md5_hash(hash)
    Digest::MD5.hexdigest hash.values.join
  end

  def log_store_started
    last_run = KsAcCaseRuns.last
    if last_run.status == 'download finished'
      last_run.update(status: 'store started')
      @run_id = last_run.id
      puts "#{"="*50} store started #{"="*50}"
    else
      p 'Cannot start store process'
      p 'Download is not finished correctly. Exiting...'
      raise "Error: Download not finished correctly!"
    end
  end

  def log_store_finished
    KsAcCaseRuns.find(@run_id).update(status: 'store finished')
    puts "#{"="*50} store finished #{"="*50}"
  end

  def print_all(*args, title: nil, line_feed: true)
    puts "#{"=" * 50}#{title}#{"=" * 50}" if title
    puts args
    puts if line_feed
  end

  def send_to_slack(message:, channel: 'U031HSK8TGF')
    Hamster.report(message: message, to: channel)
  end

end
