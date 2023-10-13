# frozen_string_literal: true

class Parser < Hamster::Parser
    
  def initialize(doc = "")
    unless doc.nil? || doc.empty?
      @html = Nokogiri::HTML5(doc.force_encoding("utf-8"))
    end
  end

  def html=(doc)
    unless doc.nil? || doc.empty?
      @html = Nokogiri::HTML5(doc.force_encoding("utf-8"))
    end
  end

  def list_links
    list = @html.css("table a")
    list.map { |el| el.attr('href').include?('http') ? el.attr('href') : (Manager::BASE_URL + el.attr('href')) }
  end
  
  def set_doc(doc)
    @html = Nokogiri::HTML5(doc.force_encoding("utf-8"))
  end

  # return array of case info
  # :activity_date, :case_id, :case_name
  def get_case_info_list
    text_area = @html.css('textarea#PostContent').text()
    content_html = Nokogiri::HTML5(text_area)
    activity_date = content_html.css('p > span.nrdate').text()

    link_tags = content_html.css('p > a')
    links = []
    case_info = {}

    link_tags.each do |tag|
      
      case_info[:court_id] = Manager::COURT_ID
      case_info[:activity_date] = activity_date
      case_info[:case_id] = tag.text()[/\d{4}-\w+-\w+/]
      nbsp = Nokogiri::HTML("&nbsp;").text
      
      case_info[:case_name] = tag.text().gsub(nbsp, " ").gsub(case_info[:case_id], '').strip unless case_info[:case_id].nil?
      unless case_info[:case_name].nil? || case_info[:case_name].scan(/IN RE:/i).empty?
        case_info[:case_name] = case_info[:case_name].gsub(/IN RE:/i, "").strip
      end
      case_info[:pdf_url] = tag.attr('href').include?('http') ? tag.attr('href') : (Manager::BASE_URL + tag.attr('href'))
      case_info[:pdf_url] = case_info[:pdf_url].gsub("../../", "/")
      
      unless case_info[:case_id].nil? || case_info[:case_id].empty? 
        if case_info[:pdf_url].include?(".PC.pdf") || case_info[:pdf_url].include?(".action.pdf")
          links.push(case_info)
        end
      end      
      case_info = {}
    end
    
    links 
  end

  def get_docket_links
    text_area = @html.css('textarea#PostContent').text()
    content_html = Nokogiri::HTML5(text_area)
    link_tags = content_html.css('p > a')
    link_tags.map{ |tag| get_full_pdf_url(tag) }
  end

  def get_full_pdf_url(tag)
    href = tag.attr('href')
    if href.include?(Manager::DOCKET_BASE_URL)
      href = href.gsub(Manager::DOCKET_BASE_URL, '/dockets')
    end
    unless href.include?('https')
      return Manager::BASE_URL + href
    else
      return href
    end
    
  end

  def get_info_from_opinion_pdf(pdf_text)
    
    case_info = { court_id: Manager::COURT_ID, }
    # if pdf_text.include?("NO. 20  15-BA-0787")
    #   case_id = "20  15-BA-0787"
    # else
    #   case_id = pdf_text[/No\.\s*\d{4}-\w+-\d+/i].gsub(/No\.\s*/i, "")
    #   case_id = pdf_text[/No\.\s*\d+-\w+-\d+/i].gsub(/No\.\s*/i, "")
    # end
    case_id = pdf_text[/No\.[\s\d]*-\w+-\d+/i].gsub(/No\.\s*/i, "") rescue nil
    
    case_info[:case_id] = case_id
    case_name = ''
    lower_court_name = ''
    status_as_of_date = ''
    activity_date = ''
    lower_case_id = ''
    
    first_index = pdf_text.index("_____")
    if first_index.nil? 
      first_index = 0
    end
    first_parag = pdf_text[0..first_index-1].gsub(/No\.\s*#{case_id}/, "").strip
    first_parag = first_parag.split(/The Supreme Court .*/)[1].strip rescue nil
    first_parag = first_parag.gsub(/\n/, " ").gsub(/\s+/, " ").strip rescue nil

    ## Output Example: 
    ## STATE OF LOUISIANA VS. RYAN MICHAEL POURCIAU
    case_info[:case_name] = first_parag

    second_parag = pdf_text.split(/_+\n/)[1].strip rescue ""
    second_parag = second_parag.gsub(/\n/, " ").gsub(/\s+/, " ")
  
    
    ## Output Example: 
    ## IN RE: Anthony Smith - Applicant Defendant; Applying For Supervisory Writ, Parish of East Feliciana, 20th Judicial District Court Number(s) 99-CR-760, Court of Appeal, First Circuit, Number(s) 2019 KW 1218;
    third_parag = pdf_text.split(/_+\n/)[2].strip rescue ""
    activity_date = third_parag[/.*\d{4}\n/].strip rescue ""
    
    status_as_of_date = third_parag.gsub(activity_date, "").strip.split(/\.\n/)[0].strip.gsub(/\n/, " ") rescue nil
    if status_as_of_date
      status_as_of_date = status_as_of_date.split(/see/i, 2)[0].strip
      status_as_of_date[-1] == '' if status_as_of_date[-1] == '-' or status_as_of_date[-1] == '.'
      status_as_of_date = status_as_of_date.strip
    end

    case_info[:lower_case_id] = second_parag.match(/, Number\(s\) (.*);/)[1] rescue nil
    if status_as_of_date && status_as_of_date.length > 255
      status_as_of_date = status_as_of_date.split('.', 2)[0].strip
    end 
    if status_as_of_date && status_as_of_date.length > 255
      status_as_of_date = status_as_of_date.split('-', 2)[0].strip
    end 
    if status_as_of_date && status_as_of_date.length > 255
      status_as_of_date = status_as_of_date[0..200]
    end
    case_info[:status_as_of_date] = status_as_of_date
    
    case_info[:lower_court_id] = get_lower_court_id(second_parag)

    case_activity = {
      court_id: Manager::COURT_ID,
      case_id: case_id,
      activity_date: activity_date,
      activity_desc: nil,
      activity_type: 'Opinion',
    }
    
    
    return {
      case_info: case_info,
      case_additional_info: get_case_additional_info(second_parag, Manager::COURT_ID, case_id),
      case_party: get_case_party(case_info[:case_name], Manager::COURT_ID, case_id),
      case_activity: case_activity,
    }
  end
def get_info_from_opinion_pdf_2019(pdf_text)
    
    case_info = { court_id: Manager::COURT_ID, }
    # case_id = pdf_text[/No\.\s*\d+-\w+-\d+/i].gsub(/No\.\s*/i, "")
    case_id = pdf_text[/No\.[\s\d]*-\w+-\d+/i].gsub(/No\.\s*/i, "") rescue nil
    case_info[:case_id] = case_id
    case_name = ''
    lower_court_name = ''
    status_as_of_date = ''
    activity_date = ''
    lower_case_id = ''

    ## Output Example: 
    ## STATE OF LOUISIANA VS. RYAN MICHAEL POURCIAU
    # case_info[:case_name] = get_case_name(pdf_text)

    activity_date = pdf_text.match(/(\d{1,2})\/(\d{1,2})\/(\d{2,4})/)
    activity_date = activity_date[3].rjust(4, "20") + "-" + activity_date[1].rjust(2, "0") + "-" + activity_date[2].rjust(2, "0")
    
    case_info[:lower_case_id] = nil
    case_info[:status_as_of_date] = nil
    case_info[:lower_court_id] = nil

    case_activity = {
      court_id: Manager::COURT_ID,
      case_id: case_id,
      activity_date: activity_date,
      activity_desc: nil,
      activity_type: 'Opinion',
    }
    
    return {
      case_info: case_info,
      case_additional_info: [],
      case_party: [],
      case_activity: case_activity,
    }
  end
  def get_case_additional_info(parag, court_id, case_id)
    
    lower_case_id = parag.match(/District Court Number\(s\) (.*),/)[1] rescue nil
    lower_case_id = lower_case_id.split(",")[0] rescue nil
    (parag_1, parag_2) = parag.split(/District Court Number\(s\) .*,/)
    
    parag_1 = (parag_1 || "") + "District"
    lower_court_name = parag_1.split(",")[-2] + ", " + parag_1.split(",")[-1] rescue nil
    if lower_court_name
      lower_court_name = lower_court_name.strip
      lower_court_name[0] = '' if lower_court_name[0] == ','
      lower_court_name = lower_court_name.strip
    end

    rlt = []
    additional_info = {}
    additional_info[:court_id] = court_id
    additional_info[:case_id] = case_id
    additional_info[:lower_court_name] = lower_court_name
    additional_info[:lower_case_id] = lower_case_id
    unless additional_info[:lower_case_id].nil? || additional_info[:lower_case_id].empty?
      rlt.push(additional_info)
    end

    additional_info = {}

    (lower_court_name, lower_case_id) = parag_2.split(", Number(s)") rescue nil

    unless lower_case_id.nil? || lower_case_id.empty?
      if lower_case_id[-1] == ';' || lower_case_id[-1] == '.'
        lower_case_id[-1] = ''
      end
    end
    additional_info = {}
    additional_info[:court_id] = court_id
    additional_info[:case_id] = case_id
    additional_info[:lower_court_name] = lower_court_name.strip rescue nil
    additional_info[:lower_case_id] = lower_case_id
    unless additional_info[:lower_case_id].nil? || additional_info[:lower_case_id].empty?
      rlt.push(additional_info)
    end

    return rlt
  end
  
  def get_lower_court_id(parag)
    match = parag[/Court of Appeal, .* Circuit,/]
    if match.nil?
      match = parag[/, .* Court of Appeal,/]
    end
    if match.nil?
      match = parag[/, .* Judicial District Court/]
    end
    if match.nil?
      return nil
    end
    Manager::LOWER_COURT_ID.keys.each do |lower_court_id|
      Manager::LOWER_COURT_ID[lower_court_id].each do |item|
        if match.downcase.include?(item)
          return lower_court_id
        end
      end
    end
    return nil
  end

  def get_case_party(case_name, court_id, case_id)

    (party_name1, party_name2) = case_name.split("VS.") rescue ["", ""]
    rlt = []
    party_name1 = party_name1.gsub(/IN RE:/, "")
    unless party_name1.nil? || party_name1.strip.empty? || party_name1.strip.length >= 255
      if party_name1.include?('IN RE:')
        party_name1 = party_name1.gsub('IN RE:', '').strip
      end
      party_info = {
        court_id: court_id,
        case_id: case_id,
        is_lawyer: 0,
        party_name: party_name1.strip,
        party_type: "party_1"
      }
      rlt.push(party_info)
    end
    
    unless party_name2.nil? || party_name2.strip.empty? || party_name2.strip.length >= 255
      if party_name2.include?('IN RE:')
        party_name2 = party_name2.gsub('IN RE:', '').strip
      end
      party_info = {
        court_id: court_id,
        case_id: case_id,
        is_lawyer: 0,
        party_name: party_name2.strip,
        party_type: "party_2"
      }
      rlt.push(party_info)
    end
    return rlt
  end

  def get_case_name(pdf_text)
    case_id = pdf_text[/No\.\s*\d{4}-\w+-\d+/i].gsub(/No\.\s*/i, "")
    text_without_case_id = pdf_text.gsub(case_id, "")
    text_parts = text_without_case_id.split(/\nVS.|\nv./i)
    casename_left = text_parts[0].split(/\n\n/).last
    casename_right = text_parts[1].split(/\n\n/).first
    casename_left + " VS. " + casename_right
  end

  def get_case_context_from(pdf_docket_text)
    
    case_ids = pdf_docket_text.scan(/.*\d{4}-\w+-\d+\n\n/i)
    context_array = [pdf_docket_text]
    item = {}
    (0..(case_ids.length-1)).each do |index|
      context_temp = context_array[-1]
      context = context_temp[context_temp.index(case_ids[index])..]
      context_array[-1] = context_temp[0..(context_temp.index(case_ids[index])-1)]
      context_array.push(get_clean_context(context))
    end
    context_array
  end
  def get_case_context_from_origin(pdf_docket_text)
    
    case_ids = pdf_docket_text.scan(/\n\d{4}-\w+-\d+\s+.*\n\n/i)
    context_array = [pdf_docket_text]
    item = {}
    (0..(case_ids.length-1)).each do |index|
      context_temp = context_array[-1]
      context = context_temp[context_temp.index(case_ids[index])..]
      context_array[-1] = context_temp[0..(context_temp.index(case_ids[index])-1)]
      context_array.push(get_clean_context(context))
    end
    context_array
  end
  def get_context_analyzed(case_context)
    head = case_context.scan(/\d{4}-\w+-\d+\n\n/i)[0]
    body = case_context.sub(head, "")
    head = head.strip
    return { head: head, body: body }
  end
  def get_context_analyzed_origin_text(case_context)
    head = case_context.strip[/^\d{4}-\w+-\d+ \s+{2,}/i]
    body = case_context.split(head, 2)[1]
    head = head.strip
    return { head: head, body: body }
  end

  def get_clean_context(docket_context)
    docket_context.gsub(/page \d+ of \d+/i, '')
  end
  
  def get_party_info(context)

    blocks = context.split(/\n{2,}/).map{|e| e.strip }
    result = []

    blocks.each do |block|
      items = []

      if block =~ /Applicant/i
        party_names = block.split(/\n/).map{|e| e.strip unless e =~ /Applicant/i}.compact
        party_type = block.split(/\n/).map{|e| e.strip if e =~ /Applicant/i}.compact[0]
        party_type[-1] = '' if party_type[-1] == ';' || party_type[-1] == '.'
        
        party_names.each do |party_name|
          item = {is_lawyer: 1, party_type: "Attorney #{party_type}", party_name: party_name}
          result << item
        end
      end
      
      if block =~ /Respondent/i
        party_names = block.split(/\n/).map{|e| e.strip unless e =~ /Respondent/i}.compact
        party_type = block.split(/\n/).map{|e| e.strip if e =~ /Respondent/i}.compact[0]
        party_type[-1] = '' if party_type[-1] == ';' || party_type[-1] == '.'
        party_names.each do |party_name|
          item = {is_lawyer: 1, party_type: "Attorney #{party_type}", party_name: party_name}
          result << item
        end
      end
    end
    result
  end
end
