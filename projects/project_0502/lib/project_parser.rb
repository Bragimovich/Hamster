require_relative '../lib/parser'
require_relative '../lib/converter'

class Project_Parser < Parser

  def initialize(run_id = 0)
    super(run_id)
  end

  def court_id
    court_name = elements_list(
      type: 'text',
      css: 'form table:nth-child(6) tr:nth-child(2) td:nth-child(2)',
      range: 0
    )
    court_id = 30 if court_name&.downcase&.include?("Appeals".downcase)
    court_id = 31 if court_name&.downcase&.include?("Supreme".downcase)
    court_id
  end

  def case_id
    elements_list(type: 'text', css: 'tr.TableHeading span#csNumber', range: 0)
  end

  def lower_case_id
    lower_case = elements_list(
      type: 'text',
      css: 'form table:nth-child(6) tr:nth-child(10) td:nth-child(2)',
      range: 0
    )
    lower_case&.split("(")&.last&.split(')')&.first&.squish
  end

  def lower_court_name
    lower_case = elements_list(
      type: 'text',
      css: 'form table:nth-child(6) tr:nth-child(10) td:nth-child(2)',
      range: 0
    )
    lower_case&.split("(")&.first&.squish
  end

  def case_info
    case_type = elements_list(type: 'text', css: 'form table:nth-child(6) tr:nth-child(2) td:nth-child(4)', range: 0)
    case_name = elements_list(type: 'text', css: 'form table:nth-child(6) tr:nth-child(3) td:nth-child(2)', range: 0)
    status_as_of_date = elements_list(type: 'text', css: 'form table:nth-child(6) tr:nth-child(3) td:nth-child(4)', range: 0)
    case_filed_date = elements_list(type: 'date', css: 'form table:nth-child(6) tr:nth-child(7) td:nth-child(2)', range: 0)
    disposition_or_status = elements_list(type: 'text', css: 'form table:nth-child(6) tr:nth-child(8) td:nth-child(4)', range: 0)
    {
      court_id: court_id,
      case_id: case_id,
      case_type: case_type,
      case_name: case_name,
      case_filed_date: case_filed_date,
      case_description: nil,
      disposition_or_status: disposition_or_status,
      status_as_of_date: status_as_of_date,
      judge_name: nil,
      lower_court_id: nil,
      lower_case_id: lower_case_id
    }
  end

  def case_additional_info
    lower_case_id_arr_str = lower_case_id
    lower_case_id_arr = lower_case_id_arr_str&.include?(',') ? lower_case_id_arr_str&.split(',') : [lower_case_id_arr_str]
    lower_case_id_arr.map do|l_case_id|
      {
        court_id: court_id,
        case_id: case_id,
        lower_court_name: lower_court_name,
        lower_case_id: l_case_id,
      }
    end
  end

  def case_party
    block_css = 'tbody#contentParties  tr.OddRow, tbody#contentParties  tr.EvenRow'
    all_data = []
    html.css(block_css).map do |html|
      party_type = elements_list(type: 'text', css: 'td', html: html, range: 0)
      party_name = elements_list(type: 'text', css: 'td', html: html, range: 1)
      lawyer_party_name = elements_list(type: 'text', css: 'td', html: html, range: 3)
       data = {
        court_id: court_id,
        case_id: case_id,
        party_type: party_type,
        party_name: party_name,
        is_lawyer: 0
      }
      all_data << data
      lawyer_data = {
        court_id: court_id,
        case_id: case_id,
        party_type: party_type,
        party_name: lawyer_party_name,
        is_lawyer: 1
      }
      all_data << lawyer_data
    end
    all_data
  end

  def case_activity
    index = 0
    block_css = "table.nested-table tr.EvenRow, table.nested-table tr.OddRow"
    arr_data = []
    arr_pdf_lists = []
    pdf_relation_indexes = []
    html.css(block_css).map.with_index do |html_br, indx|
      activity_date = elements_list(type: 'date', css: 'td:nth-child(1)', html: html_br, range: 0)
      activity_desc = elements_list(type: 'text', css: 'td:nth-child(2)', html: html_br, range: 0)
      activity_type = activity_desc&.split(' - ').dig(1)
       data = {
        court_id: court_id,
        case_id: case_id,
        activity_date: activity_date,
        activity_desc: activity_desc,
        activity_type: activity_type
      }
      data.merge!(md5_hash: @converter.to_md5(data))
      arr_data << data
      html_br.css('td')[2].css('img.documentLink').each do |_|
        mouseover('img.documentLink', index)
        index += 1
        sleep(5)
        pdf_list = []
        absolute_url_list("div#dropmenudiv a").each do |pdf_link|
          pdf_list << pdf_link
        end
        pdf_relation_indexes << indx unless pdf_list.empty?
        arr_pdf_lists << pdf_list
      end
    end
    [arr_data, arr_pdf_lists, pdf_relation_indexes]
  end
end
