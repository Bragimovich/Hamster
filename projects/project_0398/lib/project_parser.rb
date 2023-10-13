require_relative '../lib/parser'
require_relative '../lib/converter'

class Project_Parser < Parser
  attr_reader :court_id_arr, :pdf_link

  MAIN_URL = 'https://appellatecases.courtinfo.ca.gov'
  URL = 'https://appellatecases.courtinfo.ca.gov/search/'
  DIST_PATH = 'searchResults.cfm?dist='

  def initialize(run_id = 0)
    super(run_id)

    @run_id = run_id
    @court_id_arr = []
    @wrong_case_id = ["PDF", "DOC", "DOCX", "Click here"]
    @pdf_link = nil
    @appellate_links = nil
  end

  def count_courts
    elements_list(type: 'text', css: 'div.textRight p > text()', range: 1)&.split&.dig(4)&.to_i
  end

  def courts_links
    elements_list(type: 'link', css: 'div#searchResults a', url_prefix: URL)
  end

  def menu_links
    elements_list(type: 'link', css: 'div#caseDetails a', url_prefix: "#{URL}case/")
  end

  def menu_names
    elements_list(type: 'text', css: 'div#caseDetails a')
  end

  def case_info_names
    elements_list(type: 'text', css: 'div#centerColumn div.col-xs-5')
  end

  def case_info_values
    elements_list(type: 'text', css: 'div#centerColumn div.col-xs-7')
  end

  def table_texts
    elements_list(type: 'text', css: 'div#centerColumn div.col-xs-7 a')
  end

  def table_links
    elements_list(type: 'link', css: 'div#centerColumn div.col-xs-7 a')
  end

  def case_number
    elements_list(type: 'html', css: 'div#centerColumn div.col-xs-7')
  end

  def appeal_lower_case_id
    lower_case_id = elements_list(type: 'text', css: 'div#centerColumn div.col-sm-12 a', range: 0)
    tries = 5
    i = 0
    while lower_case_id.blank? || @wrong_case_id.include?(lower_case_id) do
      lower_case_id = table_texts[i]
      i += 1
      break if i == tries
    end
    lower_case_id = nil if @wrong_case_id.include? lower_case_id
    lower_case_id
  end

  def info_lower_link
    lower_case_id = elements_list(type: 'text', css: 'div#centerColumn div.col-sm-12 a', range: 0)
    lower_link = elements_list(type: 'link', css: 'div#centerColumn div.col-sm-12 a', range: 0)
    tries = 5
    i = 0
    while lower_case_id.blank? || @wrong_case_id.include?(lower_case_id) || lower_link.blank? do
      lower_case_id = table_texts[i]
      lower_link = table_links[i]
      i += 1
      break if i == tries
    end
    lower_link = nil if @wrong_case_id.include? lower_case_id
    lower_link
  end

  def get_lower_court_id(link)
    if link.include?("dist=")
      current_num = link.split('dist=').last.split("&").first
      @appellate_links&.each_with_index do |ap_link, index|
        num = ap_link.split('dist=').last.split("&").first
        return @court_id_arr[index] if current_num == num
      end
    end
    nil
  end

  def appellate_links
    url = "#{URL}#{DIST_PATH}"
    links = elements_list(type: 'link', css: 'select#DistrictSelector option', attribute: 'value', url_prefix: url)
    @appellate_links = links
    court_id = 407
    links.each_with_index do |_, index |
      @court_id_arr[index] = court_id
      court_id += 1 unless index.between?(3, 4)
    end
    links
  end

  def case_info(link, court_id, court_type)
    names = case_info_names
    values = case_info_values
    pdf_link = nil
    lower_court_id = nil
    data = {
      court_id: court_id,
      case_id: nil,
      lower_court_id: nil,
      lower_case_id: nil,
      case_name: nil,
      case_type: nil,
      case_filed_date: nil,
      disposition_or_status: nil,
      status_as_of_date: nil,
      case_description: nil,
      judge_name: nil,
      data_source_url: link,
    }
    names.each_with_index do |name, index|
      case name
      when 'Supreme Court Case:'
        if court_type == 'supreme'
          data.merge!(case_id: values[index])
        end
      when 'Court of Appeal Case:'
        if court_type == 'supreme'
          lower_case_id = appeal_lower_case_id
          lower_link = info_lower_link
          lower_court_id = get_lower_court_id(lower_link) unless lower_link.blank?
          data.merge!(lower_court_id: lower_court_id) unless lower_court_id.blank?
          data.merge!(lower_case_id: @converter.clean_string(lower_case_id)) unless lower_case_id.blank?
        elsif court_type == 'appellate'
          data.merge!(case_id: values[index])
        end
      when 'Court of Appeal Case(s):'
        lower_case_id = appeal_lower_case_id
        lower_link = info_lower_link
        lower_court_id = get_lower_court_id(lower_link) unless lower_link.blank?
        data.merge!(lower_court_id: lower_court_id) unless lower_court_id.blank?
        data.merge!(lower_case_id: @converter.clean_string(lower_case_id)) unless lower_case_id.blank?
      when 'Case Caption:'
        data.merge!(case_name: values[index])
      when 'Case Category:'
        data.merge!(case_type: values[index])
      when 'Case Type:'
        data.merge!(case_type: values[index])
      when 'Filing Date:'
        data.merge!(case_filed_date: @converter.string_to_date(values[index]))
      when 'Disposition Date:'
        disposition_or_status = @converter.string_to_date(values[index])
        data.merge!(disposition_or_status: "Closed #{disposition_or_status}") unless disposition_or_status.blank?
      when 'Start Date:'
        data.merge!(case_filed_date: @converter.string_to_date(values[index]))
      when 'Completion Date:'
        disposition_or_status = @converter.string_to_date(values[index])
        data.merge!(disposition_or_status: "Closed #{disposition_or_status}") unless disposition_or_status.blank?
      when 'Case Status:'
        data.merge!(status_as_of_date: values[index])
      when 'Trial Court Case:'
        lower_case_id = values[index]
        lower_case_id = nil if @wrong_case_id.include?(lower_case_id)
        data.merge!(lower_case_id: @converter.clean_string(lower_case_id)) if data[:lower_case_id].blank? && !lower_case_id.blank?
      when 'Supreme Court Opinion:'
        if values[index].include?('PDF')
          table_texts.each_with_index do |link_text, i|
            if link_text.to_s.strip == 'PDF'
              pdf_link = table_links[i]
            end
          end
        end
      when 'Court of Appeal Opinion:'
        if values[index].include?('PDF')
          table_texts.each_with_index do |link_text, i|
            if link_text.to_s.strip == 'PDF'
              pdf_link = table_links[i]
            end
          end
        end
      end
    end
    data[:disposition_or_status] ||= "Active" unless data[:status_as_of_date].to_s.downcase.include? "closed"
    data[:status_as_of_date] ||= data[:disposition_or_status]
    @pdf_link = pdf_link.blank? ? nil : pdf_link
    data
  end

  def case_activities(link, case_id, court_id)
    data_arr = []
    all_data = html.css('table tr')
    (1...all_data.length).step do |i|
      list = all_data[i].css('td')
      activity_date = @converter.string_to_date(list[0].text&.strip)
      activity_type = list[1].text&.strip
      list_activity_desc = list[2].to_html.split('<br><br>')
      data = {
        court_id: court_id,
        case_id: case_id,
        activity_date: activity_date,
        activity_type: activity_type,
        activity_desc: nil,
        file: nil,
        data_source_url: link
      }
      unless list_activity_desc.empty?
        list_activity_desc.each do |notes|
          notes = notes.gsub("<br>", "\n")
          notes = Nokogiri::HTML(notes).text
          notes = @converter.clean_string(notes)
          data.merge!(activity_desc: notes)
          data_arr << data
        end
      end
    end
    data_arr
  end

  def additional_info(link, case_id, court_id)
    names = case_info_names
    values = case_info_values

    return if names.empty?

    lower_link = nil
    pdf_link = nil
    data = {
      court_id: court_id,
      case_id: case_id,
      disposition: nil,
      lower_court_name: nil,
      lower_case_id: nil,
      lower_judge_name: nil,
      lower_judgement_date: nil,
      data_source_url: link
    }
    names.each_with_index do |name, index|
      case name
      when 'Court of Appeal District/Division:'
        data.merge!(lower_court_name: @converter.clean_string(values[index])) #.gsub("\n", " ")
      when 'Court of Appeal Case Number:'
        htmls = case_number
        lower_case_id = ""
        if htmls[index].include?("<br>")
          htmls[index].split('<br>').each do |val|
            lower_case_id += Nokogiri::HTML(val).text.strip + "; "
          end
          lower_case_id = lower_case_id[0...-2]
        else
          lower_case_id = values[index]
        end
        lower_case_id = nil if @wrong_case_id.include? lower_case_id
        data.merge!(lower_case_id: @converter.clean_string(lower_case_id)) unless lower_case_id.blank?
        lower_link = info_lower_link
        lower_link = "#{MAIN_URL}#{lower_link}"
      when 'Disposition:'
        data.merge!(disposition: values[index])
      when 'Disposition Date:'
        data.merge!(lower_judgement_date: @converter.string_to_date(values[index]))
      when 'Court of Appeal Opinion:'
        if values[index].include?('PDF')
          table_texts.each_with_index do |link_text, i|
            if link_text.to_s.strip == 'PDF'
              pdf_link = table_links[i]
            end
          end
        end
      end
    end
    @pdf_link = pdf_link.blank? ? nil : pdf_link
    data.merge!(lower_link: lower_link)
  end

  def case_party(link, case_id, court_id)
    data_arr = []
    all_data = html.css('table tr')
    (1...all_data.length).step do |i|
      list = all_data[i].css('td')
      arr_comments = ["<!-- party name -->", "<!-- party address -->"]
      values = values_after_comments(list[0].to_html, arr_comments, '</td>')
      arr = values.dig(0)&.strip&.split(":")
      party_type = arr.dig(1)
      party_name = arr.dig(0)
      party_address = values.dig(1)

      part = values.dig(1)&.strip&.gsub("\n", " ").split('<br>')
      size = part.size
      party_address = part[0] + part[1] if size == 3
      party_address = part[0] + part[1] + part[2] if size == 4
      splitted_address = part[1].split(",") if size == 3
      splitted_address = part[2].split(",") if size == 4
      party_city = splitted_address&.first&.strip
      party_state = splitted_address&.dig(1)&.split(" ")&.dig(0)&.to_s&.strip
      party_zip = splitted_address&.dig(1)&.split(" ")&.dig(1)&.to_s&.strip

      list_party = list[1].to_html&.split("<p></p>")
      list_party.pop
      is_lawyer = 0
      data = {
        court_id: court_id,
        case_id: case_id,
        is_lawyer: is_lawyer,
        party_type: @converter.clean_string(party_type),
        party_name: @converter.clean_string(party_name),
        party_law_firm: nil,
        party_address: @converter.clean_string(party_address),
        party_city: @converter.clean_string(party_city),
        party_state: @converter.clean_string(party_state),
        party_zip: @converter.clean_string(party_zip),
        party_description: nil,
        data_source_url: link
      }
      data_arr << data
      if list.length != 1
        list_party = list[1].to_html&.split("<p></p>")
        list_party.pop
        list_party.each do |notes|
          arr_comments = ["<!-- attorney name -->", "<!-- attorney firm -->", "<!-- attorney address -->"]
          values = values_after_comments(notes, arr_comments, '</td>')
          party_name = values[0]
          party_law_firm = values[1]
          part = values[2].split('<br>')
          size = part.size
          party_address = part[0] + part[1] if size == 3
          party_address = part[0] + part[1] + part[2] if size == 4
          splitted_address = part[1].split(",") if size == 3
          splitted_address = part[2].split(",") if size == 4
          party_city = splitted_address&.first&.strip
          party_state = splitted_address&.dig(1)&.split(" ")&.dig(0)&.to_s&.strip
          party_zip = splitted_address&.dig(1)&.split(" ")&.dig(1)&.to_s&.strip
          party_text = @converter&.string_to_nokogiri(list_party[0])&.text&.squish
          if party_text == "Pro Per" #|| party_text.blank?
            arr_comments = ["<!-- party name -->", "<!-- party address -->"]
            values = values_after_comments(list[0].to_html, arr_comments, '</td>')
            arr = values.dig(0)&.strip&.split(":")
            party_type = arr.dig(1)
            party_type += "; Pro Per" unless party_type.to_s.squish.blank?
            party_name = arr.dig(0)&.strip&.gsub("\n", " ")
            party_address = values.dig(1)&.strip&.gsub("\n", " ")
          end
          data = {
            court_id: court_id,
            case_id: case_id,
            is_lawyer: 1,
            party_type: @converter.clean_string(party_type),
            party_name: @converter.clean_string(party_name),
            party_law_firm: @converter.clean_string(party_law_firm),
            party_address: @converter.clean_string(party_address),
            party_city: @converter.clean_string(party_city),
            party_state: @converter.clean_string(party_state),
            party_zip: @converter.clean_string(party_zip),
            party_description: nil,
            data_source_url: link
          }
          data_arr << data
        end
      end
    end
    data_arr
  end
end
