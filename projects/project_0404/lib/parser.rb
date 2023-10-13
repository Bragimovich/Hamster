# frozen_string_literal: true

class Parser < Hamster::Parser
  attr_accessor :content
  attr_reader :base_info

  def init_base_details
    court_id = check_court_type(content['Court']) 
    @base_info = {court_id: court_id, case_id: content['CaseNumber'], data_source_url: Scraper::ORIGIN}
  end

  def info_hash
    case_filed_date = format_date(content['CaseStatusDate'])
    status_as_of_date = content["CaseStatus"] + (content["IsActive"] ? " (#{content['IsActive']})" : " (inactive)")
    lower_case_id = cross_refs

    hash = {
      case_name:          content['Style'],
      case_filed_date:    case_filed_date,
      case_type:          content['CaseType'],
      status_as_of_date:  status_as_of_date,
      lower_case_id:      lower_case_id
    }.merge(base_info)

    mark_empty_as_nil(hash)
  end

  def additional_info_data
    ref_cases = []

    content['CrossRefs'].each do |ref_item|
      lower_court_name = ref_item['Type']
      lower_case_ids = ref_item['Items'].map { |i| i["Value"] }

      lower_case_ids.each do |lower_case_id|
        hash = {
          case_id: content['CaseNumber'],
          lower_court_name: lower_court_name,
          lower_case_id: lower_case_id
        }.merge(base_info)

        ref_cases << mark_empty_as_nil(hash)
      end
    end if content['CrossRefs']

    ref_cases
  end

  def party_data
    parties = []
    attorneys = []

    content['Parties'].each do |party|
      party_hash = {
        is_lawyer:      0,
        party_name:     party['Name'],
        party_type:     party['ExtConnCodeDesc'],
        party_address:  party["Address"].is_a?(Hash) ? party["Address"]["Line1"] : nil,
        party_city:     party["Address"].is_a?(Hash) ? party["Address"]["City"] : nil,
        party_state:    party["Address"].is_a?(Hash) ? party["Address"]["State"] : nil,
        party_zip:      party["Address"].is_a?(Hash) ? party["Address"]["Zip"] : nil
      }.merge(base_info)

      parties << mark_empty_as_nil(party_hash)

      party['Attorneys'].each do |attorney|
        attorney_hash = {
          is_lawyer:      1,
          party_name:     attorney['Name'],
          party_type:     party['ExtConnCodeDesc'],
          party_law_firm: attorney["Address"].is_a?(Hash) ? attorney["Address"]["Line1"] : nil,
          party_address:  attorney["Address"].is_a?(Hash) ? attorney["Address"]["Line2"] : nil,
          party_city:     attorney["Address"].is_a?(Hash) ? attorney["Address"]["City"] : nil,
          party_state:    attorney["Address"].is_a?(Hash) ? attorney["Address"]["State"] : nil,
          party_zip:    attorney["Address"].is_a?(Hash) ? attorney["Address"]["Zip"] : nil
        }.merge(base_info)

        attorneys << mark_empty_as_nil(attorney_hash)
      end if party['Attorneys']
    end if content['Parties']

    parties.concat(attorneys)
  end

  def activities_data
    activities = content['Events'].each_with_object([]) do |event, arr|
      activity_desc = event["CaseEvent"]["Comment"] rescue nil
      if event['EventDocuments'].present?
        pdf_url = (Scraper::ORIGIN + "/mycase" + event['EventDocuments'][0]['DownUrl'])
        filename = event['EventDocuments'][0]['Filename']
      end

      hash = {
        activity_date: format_date(event['EventDate']),
        activity_type: event['Description'],
        activity_desc: activity_desc,
        file: filename,
        pdf_url: pdf_url
      }.merge(base_info)

      arr << mark_empty_as_nil(hash)
    end
    activities

  rescue
    return []
  end

  private

  def cross_refs
    refs = content["CrossRefs"]
    refs.map { |item| item["Items"] }.flatten.map { |i| i["Value"] }.join(" ") rescue nil
  end

  def format_date(value)
    date = value.split("/")
    month = date.shift
    day = date.shift
    Date.parse("#{date[0]}-#{month}-#{day}").strftime("%Y-%m-%d")
  rescue
    nil
  end

  def check_court_type(type)
    if type.match?(/Appea?l/)
      428
    elsif type.match?(/Supreme/)
      315
    else
      raise "#{content['CaseNumber']}: Unknown court #{type}"
    end
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : ((value.to_s.valid_encoding?)? value.to_s.squish : value.to_s.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '').squish)}
  end
end
