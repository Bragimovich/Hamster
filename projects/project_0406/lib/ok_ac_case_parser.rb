# frozen_string_literal: true

require_relative '../models/ok_ac_case_info'
require_relative '../models/ok_ac_case_party'
require_relative '../models/ok_ac_case_activities'
require_relative '../models/ok_ac_case_pdfs_on_aws'
require_relative '../models/ok_ac_case_relations_activity_pdf'
require_relative '../models/ok_ac_case_additional_info'
require_relative '../models/ok_ac_case_runs'
require 'pry'

def make_md5(hash, keys)
  values_str = ''
  keys.each { |key| values_str += (hash[key].nil? ? 'nil' : hash[key].to_s) }
  Digest::MD5.hexdigest values_str
end

class OkAcCaseParser < Hamster::Parser

  SOURCE = 'https://www.oscn.net/dockets/'
  IDX_SUB_FOLDER = 'ac_indexes/'
  CASES_SUB_FOLDER = 'ac_cases'
  COURT_ID = '460'
  CHUNK = 20000

  def initialize(*_)
    super
    @run_id = nil
    @info_unchanged, @party_unchanged, @docket_unchanged, @additional_unchanged = [], [], [], []

    @info_keys = %i[
      court_id case_id case_name case_filed_date case_type case_description
      disposition_or_status status_as_of_date judge_name data_source_url
    ]
    @additional_keys = %i[
      court_id case_id lower_court_name lower_case_id lower_judge_name
      lower_judgement_date lower_link disposition data_source_url
    ]
    @activity_keys = %i[court_id case_id activity_date activity_desc activity_type file data_source_url]
    @party_keys = %i[
      court_id case_id is_lawyer party_name party_type party_law_firm
      party_address party_city party_state party_zip party_description data_source_url
    ]
  end

  def start(update = false)
    Hamster.report(to: 'Alim Lumanov', message: "Project #0406 store started", use: :telegram)

    @update = update
    init_data
    store
    p 'store finished'

    Hamster.report(to: 'Alim Lumanov', message: "Project #0406 store finished", use: :telegram)
  rescue StandardError => e
    p 'inside outer rescue'
    p e
    Hamster.report(to: 'Alim Lumanov', message: "Project # 0406 --store->start: Error - \n#{e}", use: :telegram)
  end

  # def bind
  #   p 'started binding'
  #   cases = list_saved_cases
  #   cases.each do |case_id|
  #     case_docket = OkAcCaseActivities.where(case_id: case_id).pluck(:file, :md5_hash)
  #     next if case_docket.empty?
  #     activity_pdf_md5 = []
  #     pdfs_on_aws = OkAcCasePdfsOnAWS.where(case_id: case_id).pluck(:source_link, :md5_hash)
  #     next if pdfs_on_aws.empty?
      # case_docket.each do |item|
      #   pdf_url = item.first
      #   next if pdf_url.nil?
      #   pdf_aws_md5 = pdfs_on_aws.find { |p| p.first == pdf_url } &.last
      #   next if pdf_aws_md5.nil?
      #   new_bind = {
      #     case_activities_md5: item.last,
      #     case_pdf_on_aws_md5: pdf_aws_md5
      #   }
      #   activity_pdf_md5.push(new_bind)
      # end
      # OkAcCaseRelationsActivityPdf.insert_all(activity_pdf_md5) unless activity_pdf_md5.blank?
    # end
    # p 'finished binding'
  # end

  private

  def init_data
    @closed_cases = if @update
                      list_closed_cases
                    else
                      []
                    end
    @raw_cases = if @update
                   list_unclosed_cases
                 else
                   list_saved_cases
                 end
    @info_saved_md5 = list_unclosed_md5(OkAcCaseInfo)
    @party_saved_md5 = list_unclosed_md5(OkAcCaseParty)
    @docket_saved_md5 = list_unclosed_md5(OkAcCaseActivities)
    @additional_saved_md5 = list_unclosed_md5(OkAcCaseAditionalInfo)
  end

  def store
    mark_as_started

    files = peon.give_list(subfolder: IDX_SUB_FOLDER).sort
    files.each { |idx_file| parse_index(idx_file) }

    update_touched_deleted
    mark_as_finished
  rescue StandardError => e
    p e
    p e.full_message
    Hamster.report(to: 'Alim Lumanov', message: "Project # 0406 --store->indexes: Error - \n#{e}", use: :telegram)
  end

  def parse_index(idx_file)
    file_content = peon.give(subfolder: IDX_SUB_FOLDER, file: idx_file)
    cases = Nokogiri::HTML(file_content).css('tr.resultTableRow')
    idx_cases_folder = CASES_SUB_FOLDER + "_#{idx_file.split('_')[0]}/"
    downloaded_cases = peon.give_list(subfolder: idx_cases_folder).to_set
    cases.each do |row|
      next if row.css('a').blank?
      case_link = SOURCE + row.at('a')['href']
      case_id = row.at('a')&.text&.strip
      next unless downloaded_cases.include? "#{case_id}.gz"
      next if @closed_cases.include? case_id
      parse_case(case_link, case_id, idx_cases_folder)
    end
  end

  def parse_case(case_link, case_id, cases_folder)
    info_file_name = "#{case_id}"
    file_content = peon.give(subfolder: cases_folder, file: info_file_name)
    case_details = Nokogiri::HTML(file_content)

    return if case_details.at('body #header')&.text&.strip == 'Server Error'

    store_info(case_details, case_link, case_id)
    store_party(case_details, case_link, case_id)
    store_docket(case_details, case_link, case_id)
  rescue StandardError => e
    p case_id
    p e
    p e.full_message
    Hamster.report(to: 'Alim Lumanov', message: "Project # 0406 -->parse_case: Case - #{case_id}\n#{e}", use: :telegram)
  end

  def store_info(case_details, link, case_id)
    col_1 = case_details.at('body .caseStyle').css('td')[0].children.map { |t| t.text.gsub(',', '').squish }.reject { |e| e.empty? }
    col_2 = case_details.at('body .caseStyle').css('td')[1].children.map { |t| t.text.squish }.reject { |e| e.empty? }
    case_name = "#{col_1[0]} #{col_1[2]} #{col_1[3]}"
    detail = col_2.reject { |t| !t.include? ':' }.map { |i| i.split(':').map(&:strip) }.to_h

    ok_ac_case_info = {
      run_id: @run_id,
      touched_run_id: @run_id,
      court_id: COURT_ID,
      case_id: case_id,
      case_name: case_name,
      case_filed_date: detail['Filed'] && Date.strptime(detail['Filed'], '%m/%d/%Y'),
      disposition_or_status: detail['Closed'] && 'Closed',
      status_as_of_date: detail['Closed'] && Date.strptime(detail['Closed'], '%m/%d/%Y'),
      data_source_url: link
    }
    # binding.pry
    ok_ac_case_info[:md5_hash] = make_md5(ok_ac_case_info, @info_keys)

    if @info_saved_md5.include? ok_ac_case_info[:md5_hash]
      @info_unchanged.push(ok_ac_case_info[:md5_hash])
    else
      OkAcCaseInfo.insert ok_ac_case_info
      # bind_info_pdf_md5(ok_ac_case_info)
    end

    store_additional(case_details, detail, case_id, link)
  end

  # def bind_info_pdf_md5(ok_ac_case_info)
  #   info_pdf_md5 = []
  #   pdf_md5 = OkAcCasePdfsOnAWS.where(case_id: ok_ac_case_info[:case_id]).pluck(:md5_hash)
  #   return if pdf_md5.blank?
  #   pdf_md5.each do |md5|
  #     item = {
  #       case_info_md5: ok_ac_case_info[:md5_hash],
  #       case_pdf_on_aws_md5: md5
  #     }
  #     info_pdf_md5.push(item)
  #   end
  #   OkAcCaseRelationsInfoPdf.insert_all(info_pdf_md5) unless info_pdf_md5.blank?
  # end

  def store_additional(case_details, detail, case_id, link)
    items = case_details.css('table')[2]&.css('tbody tr')
    return if items.nil?
    items.each do |lower_court|
      col = lower_court.css('td')
      record = {
        run_id: @run_id,
        touched_run_id: @run_id,
        court_id: COURT_ID,
        case_id: case_id,
        lower_court_name: detail['Appealed from']&.strip.presence,
        lower_case_id: col[1]&.text&.strip == '-' ? nil : col[1]&.text&.strip.presence,
        lower_judge_name: col[5]&.text&.strip.presence,
        data_source_url: link
      }
      # binding.pry
      record[:md5_hash] = make_md5(record, @additional_keys)

      if @additional_saved_md5.include? record[:md5_hash]
        @additional_unchanged.push(record[:md5_hash])
      else
        OkAcCaseAditionalInfo.insert record
      end

    end
  end

  def store_party(case_details, link, case_id)
    participants = case_details.at('h2.party').next_element.children.map { |t| t.text.squish }.reject { |e| e.empty? }
    parties = participants.map { |p| p.rpartition(',').map(&:strip) }
    store_participants(parties, case_id, link)

    attorneys = case_details.css('table')[1]&.css('tbody tr')
    attorneys.each do |attorney|
      store_attorney(parties, attorney, link, case_id)
    end
  end

  def store_participants(parties, case_id, link)
    parties.each do |p|
      ok_ac_case_party = {
        run_id: @run_id,
        touched_run_id: @run_id,
        court_id: COURT_ID,
        case_id: case_id,
        is_lawyer: 0,
        party_name: p[0].presence,
        party_type: p[2].presence,
        data_source_url: link
      }
      ok_ac_case_party[:md5_hash] = make_md5(ok_ac_case_party, @party_keys)

      if @party_saved_md5.include? ok_ac_case_party[:md5_hash]
        @party_unchanged.push(ok_ac_case_party[:md5_hash])
      else
        OkAcCaseParty.insert ok_ac_case_party
      end
    end
  end

  def store_attorney(parties, attorney, link, case_id)
    attorney_info = attorney.css('td').map { |c| c.children.map { |t| t.text.squish }.reject { |e| e.empty? } }
    party_description = attorney_info[0].first.scan(/\(Bar #\d+\)/)&.first
    party_name = party_description.nil? ? attorney_info[0].first : attorney_info[0].first.sub(party_description, '').strip
    party_description = party_description&.delete('()')
    party_type = set_party_type(parties, attorney_info[1])
    party_law_firm = attorney_info[0][1] && ( attorney_info[0][1][/\d/] ? nil : attorney_info[0][1])
    n = party_law_firm ? 2 : 1
    party_address = attorney_info[0].drop(n).join(', ').presence
    address_parts = attorney_info[0].last.match(/((?:[A-Za-z]+\s?)+),\s([A-Z]{2})\s(\d{5}-?\d{4}?)/)

    ok_ac_case_party = {
      run_id: @run_id,
      touched_run_id: @run_id,
      court_id: COURT_ID,
      case_id: case_id,
      is_lawyer: 1,
      party_name: party_name,
      party_type: party_type,
      party_law_firm: party_law_firm,
      party_address: party_address.blank? ? nil : party_address,
      party_city: address_parts && address_parts[1],
      party_state: address_parts && address_parts[2],
      party_zip: address_parts && address_parts[3],
      party_description: party_description&.strip.presence,
      data_source_url: link
    }

    # binding.pry
    # return

    ok_ac_case_party[:md5_hash] = make_md5(ok_ac_case_party, @party_keys)

    if @party_saved_md5.include? ok_ac_case_party[:md5_hash]
      @party_unchanged.push(ok_ac_case_party[:md5_hash])
    else
      OkAcCaseParty.insert ok_ac_case_party
    end

  end

  def set_party_type(parties, subject)
    if subject.size != 1
      'Attorney'
    elsif subject.first == parties.first.first.split(',').map(&:strip).join(' ')
      parties.first.last
    elsif subject.first == parties.last.first.split(',').map(&:strip).join(' ')
      parties.last.last
    else
      'Attorney'
    end
  end

  def store_docket(case_details, link, case_id)
    new_docket_items = []
    docket_list = case_details.css('table.docketlist .docketRow')
    docket_list.each do |docket|
      ok_ac_case_docket = {
        run_id: @run_id,
        touched_run_id: @run_id,
        court_id: COURT_ID,
        case_id: case_id,
        activity_date: Date.strptime(docket.css('td')[0].text.strip, '%m-%d-%Y'),
        activity_desc: docket.css('td')[2].at('p').text.split("\n").compact_blank.map(&:strip).join(' ').presence,
        activity_type: docket.css('td')[1].text.strip.presence,
        file: docket.css('td')[2].at('a.doc-pdf')&.attr('href') && (SOURCE + docket.css('td')[2].at('a.doc-pdf')&.attr('href')),
        data_source_url: link
      }
      # binding.pry
      ok_ac_case_docket[:md5_hash] = make_md5(ok_ac_case_docket, @activity_keys)

      if @docket_saved_md5.include? ok_ac_case_docket[:md5_hash]
        @docket_unchanged.push(ok_ac_case_docket[:md5_hash])
      else
        new_docket_items.push(ok_ac_case_docket)
      end

    end

    unless new_docket_items.empty?
      OkAcCaseActivities.insert_all(new_docket_items)
      bind_activity_pdf_md5(new_docket_items, case_id)
    end

  end

  def bind_activity_pdf_md5(new_docket_items, case_id)
    activity_pdf_md5 = []
    pdfs_on_aws = OkAcCasePdfsOnAWS.where(case_id: case_id).pluck(:source_link, :md5_hash)
    return if pdfs_on_aws.empty?
    new_docket_items.each do |item|
      pdf_url = item[:file]
      next if pdf_url.nil?
      pdf_aws_md5 = pdfs_on_aws.find { |p| p.first == pdf_url } &.last
      next if pdf_aws_md5.nil?
      new_bind = {
        case_activities_md5: item[:md5_hash],
        case_pdf_on_aws_md5: pdf_aws_md5
      }
      activity_pdf_md5.push(new_bind)
    end
    OkAcCaseRelationsActivityPdf.insert_all(activity_pdf_md5) unless activity_pdf_md5.blank?
  end

  def update_touched_deleted
    update_touched_run_id(OkAcCaseInfo, @info_unchanged)
    update_delete_status(OkAcCaseInfo)

    update_touched_run_id(OkAcCaseAditionalInfo, @additional_unchanged)
    update_delete_status(OkAcCaseAditionalInfo)

    update_touched_run_id(OkAcCaseParty, @party_unchanged)
    update_delete_status(OkAcCaseParty)

    update_touched_run_id(OkAcCaseActivities, @docket_unchanged)
    update_delete_status(OkAcCaseActivities)
  end

  def update_touched_run_id(model, unchanged_md5)
    unchanged_md5.each_slice(CHUNK) do |md5_chunk|
      model.where(md5_hash: md5_chunk).update_all(touched_run_id: @run_id)
    end
  end

  def update_delete_status(model)
    @raw_cases.each_slice(CHUNK) do |raw_chunk|
      model.where(case_id: raw_chunk).where.not(touched_run_id: @run_id).update_all "deleted = 1"
    end
  end

  def list_lower_cases(case_id)
    OkAcCaseAditionalInfo.where(case_id: case_id).pluck(:lower_case_id).to_set
  end

  def list_unclosed_md5(model)
    model.where(case_id: @raw_cases).pluck(:md5_hash).to_set
  end

  def list_unclosed_cases
    OkAcCaseInfo.where(deleted: 0).where(disposition_or_status: nil).pluck(:case_id)
  end

  def list_saved_cases
    OkAcCaseInfo.where(deleted: 0).pluck(:case_id)
  end

  def list_closed_cases
    OkAcCaseInfo.where(deleted: 0, disposition_or_status: 'Closed').pluck(:case_id).to_set
  end

  def mark_as_started
    OkAcCaseRuns.create
    last_run = OkAcCaseRuns.last
    @run_id = last_run.id
    OkAcCaseRuns.find(@run_id).update(status: 'store started')
    # status = last_run.status
    # if status == 'download finished'
    #   OkAcCaseRuns.find(@run_id).update(status: 'store started')
    # else
    #   raise "Scrape work is not finished correctly"
    # end
  end

  def mark_as_finished
    OkAcCaseRuns.find(@run_id).update(status: 'store finished')
  end

end