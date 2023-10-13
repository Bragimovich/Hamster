# frozen_string_literal: true
require_relative '../lib/manager'

class Parser < Hamster::Parser

  COURT_ID = 86

  def initialize
    super
    # code to initialize object
  end


  def get_access_token(response)
    html = Nokogiri::HTML response.body
    data_hash = {
      viewstate:  html.xpath("//input[@id='__VIEWSTATE']//@value").text,
      viewstategenerator: html.xpath("//input[@id='__VIEWSTATEGENERATOR']//@value").text,
      eventvalidation: html.xpath("//input[@id='__EVENTVALIDATION']//@value").text
    }
    data_hash
  end


  def parse_case_info(body, run_id)

    html = Nokogiri::HTML body
    data_hash = {}

    case_name = html.xpath("//span[@id='MainContent_lblPlaintiffs']").text.squish + " v " + html.xpath("//span[@id='MainContent_lblDefendants']").inner_html.split('<br>').map(&:strip).first rescue ""
    case_filed_date = Date.strptime(html.xpath("//span[@id='MainContent_lblDateFiled']").text, '%m/%d/%Y').to_s rescue nil
    case_description = "Division: " + html.xpath("//span[@id='MainContent_lblDivision']").text.squish
    data_hash = {
      court_id: COURT_ID,
      case_id: html.xpath("//span[@id='MainContent_lblDetailHeader']//strong").text.squish,
      case_name: case_name,
      case_filed_date: case_filed_date,
      case_type: html.xpath("//span[@id='MainContent_lblCaseType']").text.strip(),
      case_description: case_description,
      disposition_or_status: nil,
      status_as_of_date: nil,
      judge_name: nil,
      data_source_url: "https://casesearch.cookcountyclerkofcourt.org/CivilCaseSearchAPI.aspx"
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash[:touched_run_id] = run_id
    data_hash
  end


  def parse_case_activities(body, run_id)
    html = Nokogiri::HTML body
    data_hash = {}

    date = Date.strptime( row.xpath(".//td")[1].text.strip(), '%m/%d/%Y').to_s rescue nil
    if html.xpath("//table[@class='table']").count > 1
      tables = html.xpath("//table[@class='table']")
    end
    return [] if tables.nil?
    array = []
    tables.each do |table|
      date = Date.strptime(table.xpath(".//td[contains(text(), 'Activity Date:')]/following-sibling::td[1]").text(), '%m/%d/%Y').to_s rescue nil
      data_hash = {
        court_id: COURT_ID,
        case_id: html.xpath("//span[@id='MainContent_lblDetailHeader']//strong").text.strip(),
        activity_date: date,
        activity_decs: table.xpath(".//td[contains(text(), 'Event Desc:')]/following-sibling::td[1]").text().squish + "; " + table.xpath(".//td[contains(text(), 'Comments:')]/following-sibling::td[1]").text().squish,
        activity_type: table.xpath(".//td[contains(text(), 'Event Desc:')]/following-sibling::td[1]").text().squish,
        data_source_url: "https://casesearch.cookcountyclerkofcourt.org/CivilCaseSearchAPI.aspx"
      }
      data_hash = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      array << data_hash
    end
    return array
  end

  def parse_case_party(body, run_id)
    html = Nokogiri::HTML body
    array = []
    for i in 1..3 do
      data_hash = {}
      if i == 1
      party_name = html.xpath("//span[@id='MainContent_lblPlaintiffs']").inner_html.split('<br>').map(&:strip) rescue []
      party_type = "Plaintiff"
      end
      if i == 2
        party_name = html.xpath("//span[@id='MainContent_lblDefendants']").inner_html.split('<br>').map(&:strip) rescue []
        party_type = "Defendants"
      end
      unless party_name.empty?
        party_name.each do |party|

          data_hash = {
            court_id: COURT_ID,
            case_id: html.xpath("//span[@id='MainContent_lblDetailHeader']//strong").text.squish,
            is_lawyer: 0,
            party_name: party.gsub("&amp;","&"),
            party_type: party_type,
            law_firm: nil,
            party_address: nil,
            party_city: nil,
            party_state: nil,
            party_zip: nil,
            party_description: nil,
            data_source_url: "https://casesearch.cookcountyclerkofcourt.org/CivilCaseSearchAPI.aspx"
          }
          data_hash = mark_empty_as_nil(data_hash)
          md5_hash = MD5Hash.new(columns: data_hash.keys)
          md5_hash.generate(data_hash)
          data_hash[:md5_hash] = md5_hash.hash
          data_hash[:run_id] = run_id
          data_hash[:touched_run_id] = run_id
          array << data_hash
        end
      end
      if i == 3
        lawyers = html.xpath('//span[@id="MainContent_lblAttorney"]').inner_html.split('<br>').map(&:strip)
        unless lawyers.empty?
          lawyers.each do |lawyer|
            data_hash = {
              court_id: COURT_ID,
              case_id: html.xpath("//span[@id='MainContent_lblDetailHeader']//strong").text.squish,
              is_lawyer: 1,
              party_name: lawyer.gsub("&amp;","&"),
              party_type: "Lawyer",
              law_firm: nil,
              party_address: nil,
              party_city: nil,
              party_state: nil,
              party_zip: nil,
              party_description: nil,
              data_source_url: "https://casesearch.cookcountyclerkofcourt.org/CivilCaseSearchAPI.aspx"
            }
            data_hash = mark_empty_as_nil(data_hash)
            md5_hash = MD5Hash.new(columns: data_hash.keys)
            md5_hash.generate(data_hash)
            data_hash[:md5_hash] = md5_hash.hash
            data_hash[:run_id] = run_id
            data_hash[:touched_run_id] = run_id
            array << data_hash
          end
        end
      end
    end
    return array
  end


  private


  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| value.to_s.empty? || value == 'null' ? nil : value }
  end

end

