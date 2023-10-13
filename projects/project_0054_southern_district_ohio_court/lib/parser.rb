require 'date'
require 'nokogiri'

require_relative 'hash_convertor'
require_relative '../models/runs'
require_relative '../models/us_case_info'
require_relative '../models/us_case_party'
require_relative '../models/us_case_lawyer'
require_relative '../models/us_case_activities'

class Parser
  COURT_ID = 36
  DEV_NAME = 'Anton Storchak'
  SCRAPE_FREQUENCY = 'daily'
  PLAINTIFF = 0
  DEFENDANT = 1
  OPEN = 'Open'
  CLOSED = 'Closed'
  CRIMINAL = 'CRIMINAL'
  CIVIL = 'CIVIL'
  PLAINTIFFS = [
    'appellant',
    'applicant',
    'claimant',
    'claimant-plaintiff',
    'claimant/petitioner',
    'counter claimant',
    'decedent-plaintiff',
    'intervener and appellant',
    'intervenor-pl',
    'minor plaintiff',
    'minor/plaintiff',
    'objector and appellant',
    'other petitioner',
    'petitioner',
    'petitioner & petitioner in pro per',
    'petitioner in pro per',
    'petitioner and appellant',
    'plaintiff',
    'plaintiff & plaintiff in pro per',
    'plaintiff in intervention',
    'plaintiff in pro per',
    'plaintiff and appellant',
    "plaintiff's aka",
    'plaintiff, & plaintiff in pro per',
    'plaintiff, cross-defendant and appellant',
    'plaintiff-minor',
    'pltf',
    "pltf's aka",
    'protected person/petitioner',
    'sc plaintiff',
    'sc pltf',
    'sccd x-cmp',
    'small claims plaintiff',
    'trustee/pltf.'
  ]
  DEFENDANTS = [
    'claimant(defendant side)',
    'claimant-defendant',
    'claimant/defendant',
    'decedent-defendant',
    'defendant',
    'defendant & defendant in pro per',
    'defendant & x-defendant & pro per',
    'defendant erroneously sued as',
    'defendant in intervention',
    'defendant in pro per',
    'defendant and respondent',
    "defendant's aka",
    "defendant's claim defendant",
    "defendant's claim plaintiff",
    'defendant, & defendant in pro per',
    'deft',
    'deft on counter claim',
    "deft's aka",
    'intervener and respondent',
    'intervenor-de',
    'minor defendant',
    'minor-defendant',
    'objector and respondent',
    'respondent',
    'respondent & respondent in pro per',
    'respondent on appeal',
    'restrained person/respondent',
    'sc defendant',
    'sc deft',
    'sc respondent',
    'sccd x-deft',
    'small claims defendant'
  ]

  def initialize(html, url, run_id, status, case_id)
    @html = html
    @url = url
    @status = status
    @run_id = run_id
    @file_case_id = case_id
    @parties = []
    @activities = []
    @hash_convertor = HashConvertor.new
  end

  def parse_case
    begin
      @case_id = parse_case_id
    rescue StandardError => e
      @case_id = @file_case_id
    end

    begin
      @disposition_or_status = parse_disposition_or_status
    rescue StandardError => e
      @disposition_or_status = ''
    end

    begin
      @case_type = parse_case_type
    rescue StandardError => e
      @case_type = ''
    end

    begin
      @judge = parse_judge
    rescue StandardError => e
      @judge = ''
    end

    begin
      @case_date = parse_case_date
    rescue StandardError => e
      @case_date = Date.new(1000, 1, 1)
    end

    if @case_type.include? CRIMINAL
      begin
        @case_title = parse_criminal_case_title
      rescue StandardError => e
        @case_title = ''
      end
    end
    if @case_type.include? CIVIL
      begin
        @case_desc = parse_civil_case_desc
      rescue StandardError => e
      end

      begin
        @case_title = parse_civil_case_title
      rescue StandardError => e
        begin
          @case_title = parse_civil_case_title_fix
        rescue StandardError => ee
          @case_title = ''
        end
      end
    end

    begin
      parse_tables
    rescue StandardError => e
    end

    begin
      parse_activities
    rescue StandardError => e
    end

    save_case_info
    save_parties
    save_activities


    ### Clean Memory
    @html = nil
    @url = nil
    @status = nil
    @run_id = nil
    @file_case_id = nil
    @parties = nil
    @activities = nil
    @hash_convertor = nil
    @case_id = nil
    @disposition_or_status = nil
    @case_type = nil
    @judge = nil
    @case_date = nil
    @case_title = nil
  end

  private

  def parse_disposition_or_status
    doc = Nokogiri::HTML @html
    doc.at('table[width="100%"] span').children.text
  end

  def parse_case_id
    doc = Nokogiri::HTML @html
    main_content = doc.at_css('[id="cmecfMainContent"]')
    main_content.search('h3').children.last.text.split('#:').last.strip.split(' ').first
  end

  def parse_case_type
    doc = Nokogiri::HTML @html
    main_content = doc.at_css('[id="cmecfMainContent"]')
    main_content.search('h3').children.last.text.split(' DOCKET FOR CASE').first.strip
  end

  def parse_case_date
    Date.strptime(/Date Filed: [0-9\/]{1,}/.match(@html)[0].gsub('Date Filed: ', ''), '%m/%d/%Y')
  end

  def parse_judge
    # /Assigned to: [A-Za-z.\s-]{1,}/.match(@html)[0].gsub('Assigned to: ', '')
    doc = Nokogiri::HTML @html
    judges = []
    judge_name = ''
    unless doc.css('td[valign="top"]').empty?
      simple_judge_data = doc.css('td[valign="top"]').map { |i| i.content }.select { |i| i.include? "Assigned to: " }
      multiply_judge_data = doc.css('td[valign="top"]').map { |i| i.content }.select { |i| i.include? "Panel: " }
      judge_data = (!simple_judge_data.empty? ? simple_judge_data[0].split("\n") : multiply_judge_data[0].split("\n"))
      judge_data.each do |i|
        judges << i.gsub("Assigned to: ", '').gsub("Panel: ", '').strip if ((!i.include? "Referred to: ") && ((i.include? "Assigned to: ") || (i.include? "Panel: ") || (i.include? "Judge")))
        judge_name = judges.join(', ').delete("\u00A0").squeeze(" ")
        break if i.include? "Referred to: "
      end
    end
    judge_name
  end

  def parse_criminal_case_title
    /Case title: [A-Za-z0-9.,\s-]{1,}/.match(@html)[0].gsub('Case title: ', '')
  end

  def parse_civil_case_desc
    /Cause: [0-9A-Za-z.,:()\s-]{1,}/.match(@html)[0].gsub('Cause: ', '')
  end

  def parse_civil_case_title
    doc = Nokogiri::HTML @html
    main_content = doc.at_css('[id="cmecfMainContent"]')
    main_content.search('table')[1].search('tr').each_with_index do |tr, index_tr|
      tr.search('td').each_with_index do |td, index_td|
        return td.children[1].text if (index_tr == 0) && (index_td == 0)
      end
    end
  end

  def parse_civil_case_title_fix
    doc = Nokogiri::HTML @html
    main_content = doc.at_css('[id="cmecfMainContent"]')
    main_content.search('table').first.search('tr').each_with_index do |tr, index_tr|
      tr.search('td').each_with_index do |td, index_td|
        return td.children[1].text if (index_tr == 0) && (index_td == 0)
      end
    end
  end

  def parse_tables
    doc = Nokogiri::HTML @html
    main_content = doc.at_css('[id="cmecfMainContent"]')
    main_content.search('table').each_with_index do |table, table_index|
      next_plaintiff = false
      next_defendant = false
      next_party_type = ''
      defendant_description = ''
      table.search('tr').each_with_index do |tr, index_tr|
        if next_defendant
          parse_party(tr, next_party_type, DEFENDANT, defendant_description)
          next_defendant = false
          defendant_description = ''
        end
        if next_plaintiff
          parse_party(tr, next_party_type, PLAINTIFF, defendant_description)
          next_plaintiff = false
          defendant_description = ''
        end
        tr.search('td').each_with_index do |td, index_td|
          if PLAINTIFFS.include? td.css('b').children.children.text.strip.gsub(/\s{1,}\([0-9]{1,}\)/, '').downcase
            next_plaintiff = true
            next_party_type = td.css('b').children.children.text.strip.gsub(/\s{1,}\([0-9]{1,}\)/, '')
          end
          if DEFENDANTS.include? td.css('b').children.children.text.strip.gsub(/\s{1,}\([0-9]{1,}\)/, '').downcase
            next_defendant = true
            next_party_type = td.css('b').children.children.text.strip.gsub(/\s{1,}\([0-9]{1,}\)/, '')
            begin
              defendant_description = table.css('td[width="40%"]').last.children.text
            rescue StandardError => e
            end
          end
          @activities_table_index = table_index if (index_tr == 0) && (index_td == 0) && (td.children.text.include? 'Date Filed')
        end
      end
    end
  end

  def parse_party(tr, party_type, party_main_type, defendant_description)
    party_name = ''
    lawyer = ''
    lawyer_firm = ''
    lawyer_additional_data = ''

    tr.search('td').each_with_index do |td, index_td|
      party_name             = td.css('b').children.text if index_td.zero?
      lawyer                 = td.search('b').first.children.text if index_td == 2
      lawyer_firm            = td.children[3].text if index_td == 2
      lawyer_additional_data = td.children.to_html if index_td == 2
    end

    @parties.push({
                      party_name: party_name,
                      party_type: party_type,
                      party_main_type: party_main_type,
                      lawyer: lawyer.gsub(/[\s]{1,}/, ' ').strip,
                      lawyer_firm: lawyer_firm.gsub(/[\s]{1,}/, ' ').strip,
                      lawyer_additional_data: lawyer_additional_data,
                      case_description: defendant_description
                  })
  end

  def parse_activities
    doc = Nokogiri::HTML @html
    main_content = doc.at_css('[id="cmecfMainContent"]')
    main_content.search('table')[@activities_table_index].search('tr').drop(1).each_with_index do |tr, index_tr|
      activity_date = ''
      activity_decs = ''
      activity_pdf  = ''
      tr.search('td').each_with_index do |td, index_td|
        activity_date = td.children.text if index_td.zero?
        begin
          activity_pdf  = td.children[0]["href"] if index_td == 1
        rescue StandardError => e
          activity_pdf = nil
        end
        activity_decs = td.children.text if index_td == 2
      end
      @activities.push({
                           activity_date: Date.strptime(activity_date, '%m/%d/%Y'),
                           activity_decs: activity_decs,
                           activity_pdf:  activity_pdf
                       })
    end
  end

  def save_case_info
    case_title            = @case_title.to_s
    case_id               = @case_id.to_s
    case_date             = @case_date
    case_type             = @case_type.to_s
    case_description      = @case_type == CIVIL ? @case_desc.to_s : ''
    disposition_or_status = @disposition_or_status.to_s
    status_as_of_date     = @status
    judge                 = @judge.to_s

    data = {
      court_id: COURT_ID.to_s,
      case_name: case_title,
      case_id: case_id,
      case_filed_date: case_date,
      case_description: case_description,
      case_type: case_type,
      disposition_or_status: disposition_or_status,
      status_as_of_date: status_as_of_date,
      judge_name: judge
    }
    md5_pacer = PacerMD5.new(data: data, table: :info)
    md5 = md5_pacer.hash

    existing_case_info = UsCaseInfo.find_by(md5_hash: md5, deleted: false)
    if existing_case_info.nil?
      case_info = UsCaseInfo.new
      case_info.run_id                = @run_id
      case_info.court_id              = COURT_ID
      case_info.case_name             = case_title
      case_info.case_id               = case_id
      case_info.case_filed_date       = case_date
      case_info.case_description      = case_description
      case_info.case_type             = case_type
      case_info.disposition_or_status = disposition_or_status
      case_info.status_as_of_date     = status_as_of_date
      case_info.judge_name            = judge
      case_info.data_source_url       = "https://ecf.ohsd.uscourts.gov/cgi-bin/DktRpt.pl?#{@url}"
      case_info.scrape_frequency      = SCRAPE_FREQUENCY
      case_info.created_by            = DEV_NAME
      case_info.touched_run_id        = @run_id
      case_info.md5_hash              = md5

      begin
        case_info.save
      rescue StandardError => e
      end
    else
      begin
        UsCaseInfo.where(["md5_hash = :md5_hash and deleted = :deleted", { md5_hash: md5, deleted: false }]).update(
          touched_run_id: @run_id, status_as_of_date: status_as_of_date
        )
      rescue StandardError => e
      end
    end
  end

  def save_parties
    @parties.each do |party|
      save_party(party)
      save_lawyer(party)
    end
  end

  def save_party(party)
    case_id                = @case_id.to_s
    party_name             = party[:party_name].to_s
    party_type             = party[:party_type].to_s
    party_address          = ''
    party_city             = ''
    party_state            = ''
    party_zip              = ''
    law_firm               = ''
    lawyer_additional_data = ''
    party_description      = @case_type == CRIMINAL ? party[:case_description].to_s : ''
    is_lawyer              = false

    data = {
      court_id: COURT_ID.to_s,
      case_id: case_id,
      party_name: party_name,
      party_type: party_type,
    }
    md5_pacer = PacerMD5.new(data: data, table: :party)
    md5 = md5_pacer.hash

    existing_party = UsCaseParty.find_by(md5_hash: md5, deleted: false)
    if existing_party.nil?
      case_party = UsCaseParty.new
      case_party.run_id                 = @run_id
      case_party.court_id               = COURT_ID
      case_party.case_id                = case_id
      case_party.party_name             = party_name
      case_party.party_type             = party_type
      case_party.party_address          = party_address
      case_party.party_city             = party_city
      case_party.party_state            = party_state
      case_party.party_zip              = party_zip
      case_party.law_firm               = law_firm
      case_party.is_lawyer              = is_lawyer
      case_party.lawyer_additional_data = lawyer_additional_data
      case_party.party_description      = party_description
      case_party.data_source_url        = "https://ecf.ohsd.uscourts.gov/cgi-bin/DktRpt.pl?#{@url}"
      case_party.scrape_frequency       = SCRAPE_FREQUENCY
      case_party.created_by             = DEV_NAME
      case_party.touched_run_id         = @run_id
      case_party.md5_hash               = md5

      begin
        case_party.save
      rescue StandardError => e
      end
    else
      begin
        UsCaseParty.where(["md5_hash = :md5_hash and deleted = :deleted", { md5_hash: md5, deleted: false }]).update(touched_run_id: @run_id)
      rescue StandardError => e
      end
    end
  end

  def save_lawyer(party)
    case_id                = @case_id.to_s
    party_name             = party[:lawyer].to_s
    party_type             = party[:party_type].to_s + " Lawyer"
    law_firm               = party[:lawyer_firm].to_s
    lawyer_additional_data = party[:lawyer_additional_data].to_s
    is_lawyer              = true
    party_description      = ''

    begin
      lawyer_data   = parse_lawyer_data(lawyer_additional_data)
      party_address = lawyer_data[:address].to_s
      party_city    = lawyer_data[:city].to_s
      party_state   = lawyer_data[:state].to_s
      party_zip     = lawyer_data[:zip].to_s
    rescue StandardError => e
      party_address = ''
      party_city    = ''
      party_state   = ''
      party_zip     = ''
    end

    data = {
      court_id: COURT_ID.to_s,
      case_id: case_id,
      party_name: party_name,
      party_type: party_type,
    }
    md5_pacer = PacerMD5.new(data: data, table: :party)
    md5 = md5_pacer.hash

    existing_party = UsCaseParty.find_by(md5_hash: md5, deleted: false)
    if existing_party.nil?
      case_party = UsCaseParty.new
      case_party.run_id                 = @run_id
      case_party.court_id               = COURT_ID
      case_party.case_id                = case_id
      case_party.party_name             = party_name
      case_party.party_type             = party_type
      case_party.party_address          = party_address
      case_party.party_city             = party_city
      case_party.party_state            = party_state
      case_party.party_zip              = party_zip
      case_party.lawyer_additional_data = lawyer_additional_data
      case_party.party_description      = party_description
      case_party.law_firm               = law_firm
      case_party.is_lawyer              = is_lawyer
      case_party.data_source_url        = "https://ecf.ohsd.uscourts.gov/cgi-bin/DktRpt.pl?#{@url}"
      case_party.scrape_frequency       = SCRAPE_FREQUENCY
      case_party.created_by             = DEV_NAME
      case_party.touched_run_id         = @run_id
      case_party.md5_hash               = md5

      begin
        case_party.save
      rescue StandardError => e
      end
    else
      begin
        UsCaseParty.where(["md5_hash = :md5_hash and deleted = :deleted", { md5_hash: md5, deleted: false }]).update(touched_run_id: @run_id)
      rescue StandardError => e
      end
    end
  end

  def parse_lawyer_data(lawyer_additional_data)
    zip_re = '(?<zip>(?>\[?\d{5}\]?(?> ?[-–] ?\[?\d{4}\]?)?)|(?>[0-9a-z]{3}\s?[-–0-9a-z]{3,4}))' # it finds US, UK and Canadian zips
    location_re = %r{(?<city>.+), (?<state>[-() a-z]+) #{zip_re}(?>, (?<country>[ a-z]+))?$}i
    address_start_line_re = %r{(?<number>[0-9]{1,}\s)}i
    # p lawyer_additional_data
    splitted_attorneys = lawyer_additional_data.split('<b>')
    splitted = splitted_attorneys[1].split('<br>')

    location_index = 0
    location_data = ''
    splitted.each_with_index do |item, index|
      match_data = item.strip.match(location_re)
      unless match_data.nil?
        location_index = index
        location_data = match_data
      end
    end

    splitted_no_location = splitted.delete_if.with_index { |x, i| i > location_index - 1 }
    found_address = false
    address_index = 0
    address_arr = []
    splitted_no_location.each_with_index do |item, index|
      match_data = item.strip.match(address_start_line_re)
      unless match_data.nil?
        found_address = true
        address_index = index
      end
      if found_address
        address_arr.push(item.strip)
      end
    end


    splitted_no_address = splitted_no_location.delete_if.with_index { |x, i| i > address_index - 1 }
    { address: address_arr.join('\n'),
      city: location_data[:city],
      state: location_data[:state],
      zip: location_data[:zip] }
  end

  def save_activities
    @activities.each do |activity|
      case_id       = @case_id.to_s
      activity_date = activity[:activity_date]
      activity_decs = activity[:activity_decs].to_s
      activity_pdf  = activity[:activity_pdf].to_s

      data = {
        court_id: COURT_ID.to_s,
        case_id: case_id,
        activity_date: activity_date.to_s,
        activity_decs: activity_decs,
        activity_pdf: activity_pdf
      }
      md5_pacer = PacerMD5.new(data: data, table: :activities)
      md5 = md5_pacer.hash

      existing_activity = UsCaseActivities.find_by(md5_hash: md5, deleted: false)
      if existing_activity.nil?
        case_activity = UsCaseActivities.new
        case_activity.run_id           = @run_id
        case_activity.court_id         = COURT_ID
        case_activity.case_id          = case_id
        case_activity.activity_date    = activity_date
        case_activity.activity_decs    = activity_decs
        case_activity.activity_pdf     = activity_pdf
        case_activity.data_source_url  = "https://ecf.ohsd.uscourts.gov/cgi-bin/DktRpt.pl?#{@url}"
        case_activity.scrape_frequency = SCRAPE_FREQUENCY
        case_activity.created_by       = DEV_NAME
        case_activity.touched_run_id   = @run_id
        case_activity.md5_hash         = md5

        begin
          case_activity.save
        rescue StandardError => e
        end
      else
        begin
          UsCaseActivities.where(["md5_hash = :md5_hash and deleted = :deleted", { md5_hash: md5, deleted: false }]).update(touched_run_id: @run_id)
        rescue StandardError => e
        end
      end
    end
  end
end