# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize(doc)
    @html = Nokogiri::HTML doc
  end

  def parse_index(page)
    main_arr = []
    page.css("table[id='caseSelectPanel:caseDetailsTableHeader']").css("tbody[id='caseSelectPanel:caseDetailsTableHeader:tb']").css('tr').each do |row|
      main_arr << {
        case_id: row.css('td')[1].css('span').first.text,
        party_name: row.css('td')[2].text,
        case_name: row.css('td')[3].text,
        case_filed_date: row.css('td')[4].text,
        case_type: row.css('td')[5].text,
        case_sub_type: row.css('td')[6].text,
        status_as_of_date: row.css('td')[7].text
      }
    end
    main_arr
  end

  def detail_data
    data_source_url = 'https://circuitclerk.lakecountyil.gov/publicAccess/html/common/selectCase.xhtml'
    data_hash = Hash.new
    case_hash = Hash.new
    table_details = @html.css('.page-container').css('table').css('tbody').css('tr')
    case_table = table_details.css('td').css("span").css('table').css('tr')
    case_table.each do |table|
      case_name = table.css('td').css("label").text.gsub(":","")
      case_value = table.css('td').css("span").text
      case_hash[case_name] =  case_value
    end
    data_hash.merge!(case_hash)

    table_party = @html.css("div[id='courtCaseDetailsPanel:filedDocsPanel:j_idt70']")
                       .css('.rf-tab-cnt')
                       .css("table[id='courtCaseDetailsPanel:filedDocsPanel:casePartiesTableHeader']")
    if table_party.present?                 
      party_arr = Array.new
      table_size = table_party.css("tbody[id='courtCaseDetailsPanel:filedDocsPanel:casePartiesTableHeader:tb']").css('tr').size
      table_size.times do |t|
        hash = Hash.new
        table_party.css("tr[id='courtCaseDetailsPanel:filedDocsPanel:casePartiesTableHeader:ch']").css('th').css('.headerText').each_with_index do |key, value|
          title_value =  table_party.css("tbody[id='courtCaseDetailsPanel:filedDocsPanel:casePartiesTableHeader:tb']").css('tr')[t].css('td')[value]
          hash[key.text] = title_value.text
        end
        party_arr << hash
      end
      party_arr
    end
    
    table_judgment = @html.css("div[id='courtCaseDetailsPanel:filedDocsPanel:j_idt131']")
                          .css('.rf-tab-cnt')
                          .css("table[id='courtCaseDetailsPanel:filedDocsPanel:caseJudgmentTableHeader']")
                         
    unless table_judgment.css("tbody[id='courtCaseDetailsPanel:filedDocsPanel:caseJudgmentTableHeader:tb']").css('tr').css('td').css('span').text.empty?
      judgment_arr = Array.new
      judgment_table_size = table_judgment.css("tbody[id='courtCaseDetailsPanel:filedDocsPanel:caseJudgmentTableHeader:tb']").css('tr').size
      judgment_table_size.times do |t|
        hash = Hash.new
        table_judgment.css("thead[id='courtCaseDetailsPanel:filedDocsPanel:caseJudgmentTableHeader:th']").css('tr').css('.rf-dt-shdr-c').each_with_index do |key, value|
          title_value =  table_judgment.css("tbody[id='courtCaseDetailsPanel:filedDocsPanel:caseJudgmentTableHeader:tb']").css('tr')[t].css('td').css('span')[value]
          hash[key.text] = title_value.text rescue nil
        end
        judgment_arr << hash
      end
      judgment_arr
    end

    table_documents_filed = @html.css("table[id='courtCaseDetailsPanel:filedDocsPanel:caseDocTableHeader']")
    if table_documents_filed.present?
      documents_filed_arr = Array.new
      documents_filed_size = table_documents_filed.css("tbody[id='courtCaseDetailsPanel:filedDocsPanel:caseDocTableHeader:tb']").css('tr').size
      documents_filed_size.times do |t|
        hash = Hash.new
        table_documents_filed.css("thead[id='courtCaseDetailsPanel:filedDocsPanel:caseDocTableHeader:th']").css('tr').css('.rf-dt-shdr-c').each_with_index do |key, value|
          title_value =  table_documents_filed.css("tbody[id='courtCaseDetailsPanel:filedDocsPanel:caseDocTableHeader:tb']").css('tr')[t].css('td').css('span')[value]
          hash[key.text] = title_value.text rescue nil
        end
        documents_filed_arr << hash
      end
      documents_filed_arr
    end

    table_events = @html.css("div[id='courtCaseDetailsPanel:filedDocsPanel:j_idt147:content']")
    if table_events.present?
      table_events_future = table_events.css("table[id='courtCaseDetailsPanel:filedDocsPanel:futureCourtEventsTableHeader']")
      table_events_previous = table_events.css("table[id='courtCaseDetailsPanel:filedDocsPanel:previousCourtEventsTableHeader']")
      events_previous_arr = Array.new
      table_events_previous_size = table_events.css("tbody[id='courtCaseDetailsPanel:filedDocsPanel:previousCourtEventsTableHeader:tb']").css('tr').size
      table_events_previous_size.times do |t|
        hash = Hash.new
        table_events_previous.css("thead[id='courtCaseDetailsPanel:filedDocsPanel:previousCourtEventsTableHeader:th']").css('tr').css('.headerText').each_with_index do |key, value|
          title_value =  table_events_previous.css("tbody[id='courtCaseDetailsPanel:filedDocsPanel:previousCourtEventsTableHeader:tb']").css('tr')[t].css('td').css('span')[value]
          hash[key.text] = title_value.text rescue nil
        end
        events_previous_arr << hash
      end
      events_previous_arr
    end
  
    { 
      case_id: data_hash["Case Number"],
      case_name: data_hash["Case Title"],
      case_filed_date: data_hash["Filed Date"],
      case_type: data_hash["Case Type"],
      status_as_of_date: data_hash["Case Status"],
      case_sub_type: data_hash["Case SubType"],
      party_name: party_arr.first["Party"],
      data_source_url: data_source_url,
      party_arr: party_arr,
      documents_filed_arr: documents_filed_arr,
      judgment_arr: judgment_arr,
      events_previous_arr: events_previous_arr
    }
  end
end
