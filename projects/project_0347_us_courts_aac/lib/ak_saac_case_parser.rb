# frozen_string_literal: true

require_relative '../models/ak_saac_case_info'
require_relative '../models/ak_saac_case_party'
require_relative '../models/ak_saac_case_activities'
require_relative '../models/ak_saac_case_pdfs_on_aws'
require_relative '../models/ak_saac_case_relations_info_pdf'
require_relative '../models/ak_saac_case_relations_activity_pdf'
require_relative '../models/ak_saac_case_additional_info'
require_relative '../models/ak_saac_case_consolidations'

class AkSaacCaseParser < Hamster::Parser

  SOURCE = 'https://appellate-records.courts.alaska.gov'
  SUPREME_COURT = {
    id: 302,
    index_folder: 'sc_indexes/',
    cases_folder: 'sc_cases/'
  }
  APPELLATE_COURT = {
    id: 403,
    index_folder: 'ac_indexes/',
    cases_folder: 'ac_cases/'
  }
  CHUNK = 10000

  def initialize(*_)
    super
    @run_id = nil
    @active_cases = []
    @active_cases_info_md5, @active_cases_party_md5, @active_cases_docket_md5 = [], [], []
    @unchanged_info, @unchanged_party, @unchanged_docket = [], [], []
  end

  def start(update: false)
    send_to_slack("Project #0347 store started")
    log_store_started

    store_supreme_court(update)
    store_appellate_court(update)

    log_store_finished
    send_to_slack("Project #0347 store finished")
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0347 error in start:\n#{e.inspect}")
  end

  private

  def store_supreme_court(update)
    @court = SUPREME_COURT
    collect_active_court_cases(@court[:id]) unless update
    parse_idx_pages
    update_touched_deleted unless update
  end

  def store_appellate_court(update)
    @court = APPELLATE_COURT
    collect_active_court_cases(@court[:id]) unless update
    parse_idx_pages
    update_touched_deleted unless update
  end

  def collect_active_court_cases(court_id)
    @active_cases = list_active_cases(court_id)
    @active_cases_info_md5 = collect_active_md5(AkSaacCaseInfo)
    @active_cases_party_md5 = collect_active_md5(AkSaacCaseParty)
    @active_cases_docket_md5 = collect_active_md5(AkSaacCaseActivities)
  end

  def parse_idx_pages
    idx_files = peon.give_list(subfolder: @court[:index_folder]).sort
    idx_files.each do |idx_file|
      parse_index(idx_file)
    end
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0347 error in parse_idx_pages:\n#{e.inspect}")
  end

  def parse_index(file)
    file_content = peon.give(subfolder: @court[:index_folder], file: file)
    cases = Nokogiri::HTML(file_content).css('.cms-table-results tbody tr')
    downloaded_cases = peon.give_list(subfolder: @court[:cases_folder]).to_set
    cases.each do |row|
      next if row.css('a').blank?
      case_link = SOURCE + row.css('a').first['href']
      case_id = row.css('a').text.strip
      next unless downloaded_cases.include? "#{case_id}_info.gz"
      parse_case(case_link, case_id)
    end
  end

  def parse_case(case_link, case_id)
    store_info(case_link, case_id)
    store_party(case_link, case_id)
    store_dockets(case_link, case_id)
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0347 error in parse_case:\n#{case_id}\n#{e.inspect}")
  end

  def store_info(link, case_id)
    info_file_name = "#{case_id}_info"
    file_content = peon.give(subfolder: @court[:cases_folder], file: info_file_name)
    info = Nokogiri::HTML(file_content)

    aac_case_info = {
      court_id: @court[:id],
      case_id: case_id,
      case_name: info.css('.col-sm-7 dd')[0].text.strip,
      case_type: info.css('.col-sm-5 dd')[0].text.strip, #info.at('dt:contains("Case Type:")').next_element.text.strip
      case_filed_date: Date.strptime(info.css('.col-sm-5 dd')[1].text.strip, '%m/%d/%Y'), #info.at('dt:contains("Date Filed:")').next_element.text.strip
      status_as_of_date: info.at('.cms-case-name span[title="Case Status"]')&.text&.strip,
      judge_name: info.css('.col-sm-12')[2]&.at('tr td:nth-child(5)')&.text&.strip.presence,
      data_source_url: link
    }
    aac_case_info[:md5_hash] = calc_md5_hash(aac_case_info)

    if @active_cases_info_md5.include? aac_case_info[:md5_hash]
      @unchanged_info.push(aac_case_info[:md5_hash])
    else
      store_one(aac_case_info, AkSaacCaseInfo)
    end

    connect_info_to_pdfs(aac_case_info)
    store_additional(info, link)
    store_consolidations(info, link)
  end

  def store_party(link, case_id)
    party_file_name = "#{case_id}_party"
    file_content = peon.give(subfolder: @court[:cases_folder], file: party_file_name)
    parties = Nokogiri::HTML(file_content).css('.cms-party-table tbody tr')

    parties.each do |party|
      addresses = party.css('td')[3].css('address')
      description = addresses.nil? ? party.css('td')[3].text.strip.presence : nil
      store_participant(case_id, party, link, description)
      addresses.each do |address|
        store_attorney(case_id, party, address, link)
      end
    end
  end

  def store_participant(case_id, party, link, description)
    aac_case_party = {
      court_id: @court[:id],
      case_id: case_id, #info.at('.cms-case-name span').text.split[0].strip
      is_lawyer: 0,
      party_name: party.css('td')[0].text.strip.presence,
      party_type: party.css('td')[2].text.strip.presence,
      party_description: description,
      data_source_url: link
    }
    aac_case_party[:md5_hash] = calc_md5_hash(aac_case_party)

    if @active_cases_party_md5.include? aac_case_party[:md5_hash]
      @unchanged_party.push(aac_case_party[:md5_hash])
    else
      store_one(aac_case_party, AkSaacCaseParty)
    end
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0347 error in store_participant:\n#{case_id}\n#{e.inspect}")
  end

  def store_attorney(case_id, party, address, link)
    attorney_name = address.at('strong').text.strip
    address_line_1 = address.css('br')[0].next.text.strip
    address_line_2 = address.css('br')[1].next.text.strip
    address_parts = address_line_2.match(/((?:[A-Za-z]+\s?)+),\s([A-Z]{2})\s(\d{5}-?\d{4}?)/)

    aac_case_party = {
      court_id: @court[:id],
      case_id: case_id, #info.at('.cms-case-name span').text.split[0].strip
      is_lawyer: 1,
      party_name: attorney_name,
      party_type: party.css('td')[2].text.strip.presence,
      party_law_firm: nil,
      party_address: address_line_1.blank? ? nil : address_line_1,
      party_city: address_parts.nil? ? nil : address_parts[1],
      party_state: address_parts.nil? ? nil : address_parts[2],
      party_zip: address_parts.nil? ? nil : address_parts[3],
      party_description: address.css('br')[2].next.text.strip.presence,
      data_source_url: link
    }
    aac_case_party[:md5_hash] = calc_md5_hash(aac_case_party)

    if @active_cases_party_md5.include? aac_case_party[:md5_hash]
      @unchanged_party.push(aac_case_party[:md5_hash])
    else
      store_one(aac_case_party, AkSaacCaseParty)
    end
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0347 error in store_attorney:\n#{case_id}\n#{e.inspect}")
  end

  def store_dockets(link, case_id)
    docket_file_name = "#{case_id}_docket"
    file_content = peon.give(subfolder: @court[:cases_folder], file: docket_file_name)
    docket = Nokogiri::HTML(file_content).css('.cms-docket-table tbody tr')
    docket.each do |activity|
      store_activity(activity, case_id, link)
    end
  end

  def store_activity(activity, case_id, link)
    aac_case_activity = parse_activity(activity, case_id, link)

    if @active_cases_docket_md5.include? aac_case_activity[:md5_hash]
      @unchanged_docket.push(aac_case_activity[:md5_hash])
    else
      store_one(aac_case_activity, AkSaacCaseActivities)
      connect_activity_to_pdf(activity, aac_case_activity[:md5_hash], case_id)
    end
  end

  def parse_activity(activity, case_id, link)
    case_activity = {
      court_id: @court[:id],
      case_id: case_id, #info.at('.cms-case-name span').text.split[0].strip
      activity_date: Date.strptime(activity.css('td')[4].text.strip, '%m/%d/%Y'),
      activity_desc: activity.css('td')[2].text.strip.presence,
      activity_type: activity.css('td')[3].text.strip.presence,
      file: nil,
      data_source_url: link
    }
    case_activity[:md5_hash] = calc_md5_hash(case_activity)
    case_activity
  end

  def connect_info_to_pdfs(case_info)
    info_pdf_md5 = []
    stores_aws_pdf_md5 = AkSaacCasePdfsOnAWS.where(case_id: case_info[:case_id]).pluck(:md5_hash)
    return if stores_aws_pdf_md5.blank?
    stored_relations_md5 = AkSaacCaseRelationsInfoPdf.where(case_info_md5: case_info[:md5_hash]).pluck(:case_pdf_on_aws_md5)
    stores_aws_pdf_md5.each do |md5|
      next if stored_relations_md5.include?(md5)
      relation = {
        court_id: case_info[:court_id],
        case_id: case_info[:case_id],
        case_info_md5: case_info[:md5_hash],
        case_pdf_on_aws_md5: md5
      }
      info_pdf_md5.push(relation)
    end
    store_all(info_pdf_md5, AkSaacCaseRelationsInfoPdf, with_run_id: false)
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0347 error in connect_info_to_pdfs:\n#{case_info[:case_id]}\n#{e.inspect}")
  end

  def connect_activity_to_pdf(activity, activity_md5, case_id)
    path_to_pdf = activity.css('td')[1].at('a')&.attr('href') #docket.at('td a')&.attr('href')
    return if path_to_pdf.nil?
    pdf_url = SOURCE + path_to_pdf
    pdf_md5 = AkSaacCasePdfsOnAWS.find_by(source_link: pdf_url)&.md5_hash
    return if pdf_md5.nil?
    relation = {
      court_id: @court[:id],
      case_activities_md5: activity_md5,
      case_pdf_on_aws_md5: pdf_md5
    }
    store_one(relation, AkSaacCaseRelationsActivityPdf, with_run_id: false)
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0347 error in connect_activity_to_pdf:\n#{case_id}\n#{e.inspect}")
  end

  def store_additional(info, link)
    items = info.css('.col-sm-12')[2]&.css('tbody tr')
    return if items.nil?
    new_additional = []
    unchanged_additional = []
    case_id = info.at('.cms-case-name span').text.split[0].strip
    stored_additional = list_additional_md5(case_id)
    items.each do |lower_court|
      record = {
        court_id: @court[:id],
        case_id: case_id,
        lower_court_name: lower_court&.at('td:nth-child(4)')&.text&.strip.presence,
        lower_case_id: lower_court&.at('td:nth-child(1)')&.text&.strip.presence,
        lower_judge_name: lower_court&.at('td:nth-child(5)')&.text&.strip.presence,
        lower_judgement_date: (Date.strptime(lower_court&.at('td:nth-child(2)')&.text&.strip, '%m/%d/%Y') rescue nil),
        data_source_url: link
      }
      record[:md5_hash] = calc_md5_hash(record)

      if stored_additional.include? record[:md5_hash]
        unchanged_additional.push(record[:md5_hash])
      else
        new_additional.push(record)
      end
    end
    store_all(new_additional, AkSaacCaseAdditionalInfo)
    update_touched_run_id(unchanged_additional, AkSaacCaseAdditionalInfo)
    update_deleted_by_case_id(case_id, AkSaacCaseAdditionalInfo)
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0347 error in store_additional:\n#{case_id}\n#{e.inspect}")
  end

  def store_consolidations(info, link)
    items = info.css('.col-sm-12')[3]&.css('tbody tr')
    return if items.nil?
    case_id = info.at('.cms-case-name span').text.split[0].strip
    new_consolidations = []
    unchanged_consolidations = []
    stored_consolidations = list_consolidations_md5(case_id)
    items.each do |row|
      record = {
        court_id: @court[:id],
        case_id: case_id,
        consolidated_case_id: row.at('a')&.text&.strip.presence,
        consolidated_case_name: row.css('td')[1]&.text&.strip.presence,
        data_source_url: link
      }
      record[:md5_hash] = calc_md5_hash(record)

      if stored_consolidations.include? record[:md5_hash]
        unchanged_consolidations.push(record[:md5_hash])
      else
        new_consolidations.push(record)
      end
    end
    store_all(new_consolidations, AkSaacCaseConsolidations)
    update_touched_run_id(unchanged_consolidations, AkSaacCaseConsolidations)
    update_deleted_by_case_id(case_id, AkSaacCaseConsolidations)
  rescue StandardError => e
    print_all e, e.full_message, title: " ERROR "
    send_to_slack("project_0347 error in store_consolidations:\n#{case_id}\n#{e.inspect}")
  end

  def update_touched_deleted
    update_touched_run_id(@unchanged_info, AkSaacCaseInfo)
    update_delete_status(AkSaacCaseInfo)

    update_touched_run_id(@unchanged_party, AkSaacCaseParty)
    update_delete_status(AkSaacCaseParty)

    update_touched_run_id(@unchanged_docket, AkSaacCaseActivities)
    update_delete_status(AkSaacCaseActivities)
  end

  def store_all(records, model, with_run_id: true)
    return if records.empty?

    records.each { |rec| add_run_id(rec) } if with_run_id

    records.each_slice(CHUNK) do |chunk|
      model.insert_all chunk
    end
  end

  def store_one(record, model, with_run_id: true)
    return if record.empty?

    add_run_id(record) if with_run_id
    model.insert record
  end

  def update_touched_run_id(unchanged_md5, model)
    unchanged_md5.each_slice(CHUNK) do |md5_chunk|
      model.where(md5_hash: md5_chunk).update_all(touched_run_id: @run_id)
    end
  end

  def update_delete_status(model)
    @active_cases.each_slice(CHUNK) do |active_cases_chunk|
      model.where(case_id: active_cases_chunk).where.not(touched_run_id: @run_id).update_all(deleted: 1)
    end
  end

  def update_deleted_by_case_id(case_id, model)
    model.where(case_id: case_id).where.not(touched_run_id: @run_id).update_all(deleted: 1)
  end

  def list_additional_md5(case_id)
    AkSaacCaseAdditionalInfo.where(case_id: case_id).pluck(:md5_hash)
  end

  def list_consolidations_md5(case_id)
    AkSaacCaseConsolidations.where(case_id: case_id).pluck(:md5_hash)
  end

  def collect_active_md5(model)
    model.where(case_id: @active_cases).pluck(:md5_hash).to_set
  end

  def list_active_cases(court_id)
    AkSaacCaseInfo.where(court_id: court_id, deleted: 0).where.not(status_as_of_date: 'Closed')
               .or(AkSaacCaseInfo.where(court_id: court_id, deleted: 0, status_as_of_date: nil))
               .pluck(:case_id)
  end

  def add_run_id(record)
    record[:run_id] = @run_id
    record[:touched_run_id] = @run_id
  end

  def calc_md5_hash(hash)
    Digest::MD5.hexdigest hash.values.join
  end

  def log_store_started
    last_run = AkSaacCaseRuns.last
    if last_run.status == 'download finished'
      last_run.update(status: 'store started')
      @run_id = last_run.id
      p 'store started'
    else
      p 'Cannot start store process'
      p 'Download is not finished correctly. Exiting...'
      raise "Error: Download not finished"
    end
  end

  def log_store_finished
    AkSaacCaseRuns.find(@run_id).update(status: 'store finished')
    p 'store finished'
  end

  def print_all(*args, title: nil, line_feed: true)
    puts "#{"=" * 50}#{title}#{"=" * 50}" if title
    puts args
    puts if line_feed
  end

  def send_to_slack(message)
    Hamster.report(to: 'U031HSK8TGF', message: message)
  end

end
