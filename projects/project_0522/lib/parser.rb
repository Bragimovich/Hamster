require_relative '../lib/helper'

class Parser < Hamster::Parser
  include Helper
  attr_reader :html, :case_id, :court_id, :case_num

  def initialize(doc, params={})
    self.html = doc
    configure_variables(params) unless params.empty?
  end

  def html=(doc)
    @html = Nokogiri::HTML5(doc.force_encoding("utf-8"))
  end

  def last_page
    @html.css("option").map {|link| link['value'] }.last.to_i
  end

  def row_count
    @html.at_css("input#pagesize")['value']
  end

  def curr_page
    @html.at_css("input#currpage")['value']
  end

  def list_link
    list = @html.css("a").map { |link| link['href'] }.uniq.select { |el| el =~ /^index\.php\?cn=\d+#dispArea$/ }
    list.map! { |link| yield link } if block_given?
    list
  end

  def get_pdf_links
    @html.css("tr[class^='dockpdf-'] td a[title='View Document']").map { |el| el['href'] }.uniq
  end

  def find_info_html_link
    Scraper::ORIGIN + @html.at_css("a[href*='printdocket']").attr('href') rescue nil
  end

  def find_opinion_pdf_link
    @html.at_css("a[href*='Opinions']").attr('href') rescue nil
  end

  def content_from_opinion
    elements_b = @html.css("b").select { |el| el.text.match?(/^[[:space:]]{2}|^X+[[:space:]]{2}/) }
    elements_ul = @html.css("ul").map { |el| el.text.squish }
    raise if elements_ul.empty? || elements_b.empty?

    cases_info = elements_b.each_with_index.with_object({}) do |(el, i), hash|
      if el.children.size == 1
        case_id = el.text.gsub(/^X+/, '').squish
        hash[case_id] ||= []
        hash[case_id] << {description: elements_ul[i]}
      else
        case_id = el.at_css('a').text.gsub(/^X+/, '').squish
        hash[case_id] ||= []
        hash[case_id] << {description: elements_ul[i]}
      end
    end
    cases_info.transform_values { |arr| arr.first}
  end

  def prepare_info_hashes(hash_more_info)
    content = extract_info_content
    case_name = content[1] && !content[1].empty? ? content[1] : check_case_name
    case_filed_date = ruling_date(content[-1]) 
    
    base_info = {
      court_id: court_id,
      case_id: case_id,
      lower_case_id: check_lower_case_id(content[3]),
      data_source_url: @source_url
    }

    info_hash = {
      case_name: case_name,
      case_filed_date: case_filed_date,
    }.merge(base_info).merge(hash_more_info) {|_key, oldval, newval| oldval || newval}

    additional_info_hash = {
      lower_court_name: content[2],
      lower_judge_name: judge_name(content[4]),
      lower_judgement_date: case_filed_date
    }.merge(base_info).merge(hash_more_info) {|_key, oldval, newval| oldval || newval}

    info_hash = mark_empty_as_nil(info_hash)
    additional_info_hash = mark_empty_as_nil(additional_info_hash)

  [MsSaacCaseInfo.flail { |k| [k, info_hash[k]] }, MsSaacCaseAdditionalInfo.flail { |k| [k, additional_info_hash[k]] }]
  end

  def prepare_party_array
    arr_hashes = []
    curr_party_type = nil

    @html.css("table:not([width])").css("table:not([style])").each do |el|
      next if el.css('tr').empty? || el.text.squish.empty?
      first_row = el.css("tr:first-child td")
      party_type = first_row[0].text.squish
      curr_party_type = party_type unless party_type.empty?
      party_name = first_row[1].text.squish
      next if party_name == "No Attorney Representation" || party_name == "No Party Association" || party_name.empty?
      is_lawyer = el.css('tr').count == 2 ? 1 : 0

      party_hash = {
        court_id: court_id,
        case_id: case_id,
        is_lawyer: is_lawyer,
        party_name: party_name,
        party_type: party_type(curr_party_type, is_lawyer),
        data_source_url: @source_url
      }

      party_hash = mark_empty_as_nil(party_hash)
      arr_hashes << MsSaacCaseParty.flail { |k| [k, party_hash[k]] }
    end
    arr_hashes.uniq
  end

  def prepare_docket_array
    table = @html.css("div[id^='dockList-']")
    return [] if table.empty?

    activities_array = []
    table.each do |div|
      tr_array = div.css('tr')
      main_info = tr_array.first
      date = format_date(main_info.at_css("td.DATE").text)
      desc = main_info.at_css("td.DESCRIPTION").text
      type = extract_type(desc)
      pdf_info = tr_array.last if tr_array.size > 1
      pdf_link = pdf_info.at_css("a[title='View Document']").attr('href') rescue nil
      pdf_link = pdf_link.match?("Opinion") ? pdf_link.gsub("/..", Scraper::ORIGIN).gsub("%5C", "/") : "#{Scraper::ORIGIN}#{pdf_link}" if pdf_link
      docket_hash = {
        court_id: court_id,
        case_id: case_id,
        activity_date: date,
        activity_desc: desc,
        activity_type: type,
        file: pdf_link,
        data_source_url: @source_url
      }

      docket_hash = mark_empty_as_nil(docket_hash)
      activities_array << MsSaacCaseActivities.flail { |k| [k, docket_hash[k]] }
    end
    activities_array.uniq
  end

  def get_aws_link_hash(aws_link, pdf_link, type)
    {
      court_id: court_id,
      case_id: case_id,
      source_link: pdf_link,
      aws_link: aws_link,
      source_type: "#{type}"
    }
  end

  def parse_more_info
    @html.at_css("p.description").text.strip
  end

  class << self
    def create_body(data)
      "<p class='description'>#{data[:description]}</p>"
    end

    def scan_pdf(content)
      content = content.gsub(/\n+/, "\n").squeeze(' ').strip
      judgement_date = content[/(?<=\nDATE OF JUDGMENT:)\s?(\d|\/){10}/i]
      judgement_date = format_date(judgement_date.squish) if judgement_date
      check_case_type = content[/(?<=NATURE OF THE CASE:).*?(?=TRIAL COURT DISPOSITION|DISPOSITION|\n)/i]
      start_disposition = content =~ /\nDISPOSITION/i
      end_disposition = content =~ /\nMOTION/i

      if start_disposition && end_disposition
        disposition = content[/(?<=\nDISPOSITION:).*?(?=\nMOTION)/mi].squish[..254] rescue nil
      elsif start_disposition
        disposition = content[/(?<=\nDISPOSITION:).*?(?=\n)/mi].squish[..254] rescue nil
      end

      status = disposition[/.*?(?=-|\d)/mi].squish.delete_suffix(':').delete_suffix(';').delete_suffix('.')[..254] rescue nil                                    
      case_type = check_case_type.squish rescue nil
      data_hash = {
        case_type: case_type, 
        disposition_or_status: disposition, 
        status_as_of_date: status, 
        case_filed_date: judgement_date,
        lower_judgement_date: judgement_date
      }
      mark_empty_as_nil(data_hash)
    end
  end

  private

  def extract_info_content
    @html.css("td.tccell").map { |el| el.text.squish }
  end

  def configure_variables(params)
    params.each { |k,v| instance_variable_set("@#{k}", v) }
    @case_id = @html.css("td.casenum").first.text 
    @court_id = @case_id.match?(/coa/i) ? 2 : 1
    @source_url = "#{Scraper::MAIN_URL}?cn=#{@case_num}#dispArea"
  rescue
    raise "File #{case_num}__info is broken!"
  end

  def ruling_date(row)
    value = row[/(?<=Ruling Date:).*/].squish rescue nil
    value&.empty? ? nil : format_date(value)
  end

  def judge_name(row)
    value = row[/(?<=The Honorable).*/].squish rescue nil
    value&.empty? ? nil : value
  end

  def check_case_name
    case_name = @html.css("table:nth-child(2) tr:not([style]):not([id])")[1].text.squish rescue nil
    return case_name if case_name.present? && case_name.include?('v')
    nil
  end

  def check_lower_case_id(row)
    value = row[/(?<=Trial Court Case #).*/].squish rescue nil
    value&.empty? ? nil : value
  end

  def party_type(type, status)
    status.zero? ? type.split('Attorneys').first.squish : type.squish rescue nil
  end

  def extract_type(str)
    ['#', 'filled on', 'by the', 'Filed on', 'filed on', 'filed by', '-'].each do |template| 
      return str.split(template).first.squish if str.include?(template) 
    end 
    str
  end
end
