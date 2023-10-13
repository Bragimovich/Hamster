# frozen_string_literal: true

class Parser < Hamster::Parser
  attr_writer :type

  def initialize(doc)
    @html = Nokogiri::HTML(doc.force_encoding(Encoding::ISO_8859_1))
    @link = "https://fcdcfcjs.co.franklin.oh.us/CaseInformationOnline/imageLinkProcessor.pdf?coords="
    files_obj = @html.css("script").text.scan(/images\[\'(\d{4})\'\]\s?=\s?encodeURIComponent\(\'(\S+)\'\);/)
    obj_tmp = {}
    files_obj.each {|item| obj_tmp.merge!({item[0].to_s => item[1].to_s })}
    @files = JSON.parse(obj_tmp.to_json)
  end

  def check_next_page
    forward = @html.css("input[name=forward]").first.attr("value") rescue nil
    forward.scan(/(\d{2})(\w{2})(\d{6})/).flatten rescue nil
  end

  def domestic_cases_data
    table = @html.css("table")[4]
    info_table = table.css(">tr").last.css(">td>table")[0]
    @plaintiff_table = table.css(">tr").last.css(">td>table")[2].css("tbody[id='plaintiff-body']")
    @defendant_table = table.css(">tr").last.css(">td>table")[2].css("tbody[id='defendant-body']")
    @files_t = table.css(">tr").last.css(">td>table")[5]

    @case_id = info_table.css("tr")[3].children[1].text rescue nil
    @disposition_or_status = info_table.css("tr")[3].children[2].text rescue nil
    @status_as_of_date = info_table.css("tr")[3].children[3].text rescue nil
    raw_date_filed = info_table.css("tr")[3].children[4].text.split('/') rescue nil
    @case_filed_date = Date.parse((raw_date_filed[2] + raw_date_filed[0] + raw_date_filed[1])).strftime("%Y-%m-%d") rescue nil
    @judge_name = table.css(">tr").last.css(">td>table")[1].css("tr")[3].children[1].text

    case_hash
  end

  def civil_cases_data
    table = @html.css("table[id=main]")
    info_table = table.css(">tr").last.css(">td>table")[0]
    @plaintiff_table = table.css(">tr").last.css(">td>table")[2].css("tbody[id='plaintiff-body']")
    @defendant_table = table.css(">tr").last.css(">td>table")[2].css("tbody[id='defendant-body']")
    @files_t = table.css(">tr").last.css(">td>table")[4]

    @case_id = info_table.css("tr")[2].children[1].text rescue nil
    @disposition_or_status = info_table.css("tr")[2].children[2].text rescue nil
    @status_as_of_date = info_table.css("tr")[2].children[3].text rescue nil
    raw_date_filed = info_table.css("tr")[2].children[4].text.split('/') rescue nil
    @case_filed_date = Date.parse((raw_date_filed[2] + raw_date_filed[0] + raw_date_filed[1])).strftime("%Y-%m-%d") rescue nil
    @judge_name = table.css(">tr").last.css(">td>table")[1].css("tr")[2].children[1].text

    case_hash
  end

  def case_hash
    { case_id: @case_id,
      disposition_or_status: @disposition_or_status,
      status_as_of_date: @status_as_of_date,
      case_filed_date: @case_filed_date,
      judge_name: @judge_name,
      appellants: appellee(@plaintiff_table),
      appellee: appellee(@defendant_table),
      files_table: files_table(@files_t),
      judgment: @judgment
    }
  end

  def appellate_cases_data
    table = @html.css("table[id=main]")
    info_table = table.css(">tr").last.css(">td>table")[0]
    appellants_table = table.css(">tr").last.css(">td>table")[1]
    appellee_table = table.css(">tr").last.css(">td>table")[2]
    files_t = table.css(">tr").last.css(">td>table")[5]
    files_t.nil? ? files_t = table.css(">tr").last.css(">td>table")[3] : files_t = table.css(">tr").last.css(">td>table")[5]

    case_id = info_table.css("tr")[2].children[0].text.split('-').join(' ') rescue nil
    type = info_table.css("tr")[2].children[1].text rescue nil
    lower = info_table.css("tr")[2].children[2].text rescue nil
    lc_case_ord_date = info_table.css("tr")[2].children[3].text.split('/') rescue nil
    lower_judgement_date = Date.parse((lc_case_ord_date[2] + lc_case_ord_date[0] + lc_case_ord_date[1])).strftime("%Y-%m-%d") rescue nil
    raw_date_filed = info_table.css("tr")[2].children[4].text.split('/') rescue nil
    date_filed = Date.parse((raw_date_filed[2] + raw_date_filed[0] + raw_date_filed[1])).strftime("%Y-%m-%d") rescue nil
    status = info_table.css("tr")[2].children[5].text rescue nil
    style_code = info_table.css("tr")[3].children[1].text rescue nil
    lower_court_judge = info_table.css("tr")[4].children[1].text rescue nil

    { case_id: case_id, 
      case_type: type,
      lower_case_id: lower,
      lower_judgement_date: lower_judgement_date,
      case_filed_date: date_filed, 
      status_as_of_date: status, 
      case_description: style_code, 
      lower_judge_name: lower_court_judge,
      appellants: appellee(appellants_table),
      appellee: appellee(appellee_table),
      files_table: files_table(files_t)
    }
  end
  
  def appellee(table)
    tr = table.css("tr")
    name = []
    attorney = []
    raw_name_info = []
    name_info = []
    raw_attorney_info = []
    attorney_info = []
    attorney_firm = []

    if @type == "AP"
      party_type =  table.children.css("tr").css("td").first.text rescue nil
      begin_index = 4
      if tr[begin_index].children.nil?
        begin_index += 1
      end
      if tr[begin_index].children.children[1].nil?
        begin_index = 5
      end
    else
      party_type =  table.css("tbody").attr("id").text.split("-").first.capitalize
      begin_index = 0
    end

    tr[begin_index..-1].each_with_index do |td, index|
      unless td.children.children.text.empty?
        if index.even?
          name.push(td.children[1].text.strip)
          if @type == "DR"
            attorney.push(td.children[3].text)
          else
            attorney.push(td.children[2].text)
          end
        else
          raw_name_info.push(td.children[1].inner_html)
            name_info.push(parse_lawyer_data(td.children[1].inner_html(:encoding => 'UTF-8')))
          if @type == "DR"
            buf_attroney = td.children[3].inner_html
          else
            buf_attroney = td.children[2].inner_html
          end
          arr_attorny = buf_attroney.split("<br><br>")
            arr_attorny.each_with_index do |elem, elem_index|
            split_elem = elem.split("<br>")
              if elem_index > 0
                attorney.push(split_elem[0])
                attorney_firm.push(split_elem[1])
                raw_attorney_info.push(split_elem[1..-1].join(";"))
                attorney_info.push(parse_lawyer_data(split_elem[0..-1].join(";"))) 
              elsif  elem_index == 0
                attorney_firm.push(split_elem[0])
                raw_attorney_info.push(split_elem[0..-1].join(";"))
                attorney_info.push(parse_lawyer_data(split_elem[0..-1].join(";"))) 
              end
            end
          end
        end
      end

    {
      name: name.empty? ? nil : name,
      party_type: party_type,
      attorney: attorney.empty? ? nil : attorney,
      attorney_firm: attorney_firm.empty? ? nil : attorney_firm,
      name_raw_info: raw_name_info.empty? ? nil : raw_name_info,
      name_info: name_info.empty? ? nil : name_info,
      attorney_raw_info: raw_attorney_info.empty? ? nil : raw_attorney_info,
      attorney_info: attorney_info.empty? ? nil : attorney_info
    }
  end

  def files_table(files_t)
    begin
    tr = files_t.css(">tr").last
    files = []
    unless tr.nil?
      tr.css(">td tbody[id=docket-body]>tr[class!=detail]").each do |elem|
        buff_elem = elem.inner_html.gsub("\n", "").gsub("   ","").gsub("  ","")
        matches = buff_elem.match(/<td>.*?<\/td><td>(?<date>\d{2}\/\d{2}\/\d{2,4})<\/td><td>(?<name>.+?)<\/td><td><a\s+href="javascript:openImageLink\('(?<id_image>\d{4})'\)">.+?<td>(?<fiche>\w+)<\/td><td>(?<frame>\w+)<\/td><td>(?<page>\d+)<\/td>/)
        desc = elem.next_element.css('tr').map { |el| el.text } rescue ""

        if desc.join('; ').include?("DATE - JUDGMENT:")
          @judgment = judgment_hash(elem)
        end rescue nil

        unless matches.nil?
          id_image = matches[:id_image]
          file = @link + @files[id_image].gsub("+","%2B").gsub("/","%2F").gsub("=","%3D") unless @files[id_image].nil?
          files.push(
            {
              date: Date.parse((matches[:date].to_s.split('/')[2] + matches[:date].to_s.split('/')[0] + matches[:date].to_s.split('/')[1])).strftime("%Y-%m-%d"),
              name: matches[:name],
              link: file,
              desc: desc.empty? || desc.nil? ? nil : desc.join('; ')
            }
          )
        end
      end
    end
    return files.dup
    end
  end

  def parse_lawyer_data(attorney_info)
    zip_re = '(?<zip>(?>\[?\d{5}\]?(?> ?[-–] ?\[?\d{4}\]?)?)|(?>[0-9a-z]{3}\s?[-–0-9a-z]{3,4}))' # it finds US, UK and Canadian zips
    location_re = %r{(?<city>.+), (?<state>[-() a-z]+) #{zip_re}(?>, (?<country>[ a-z]+))?$}i
    address_start_line_re = %r{(?<number>[0-9]{1,}\s)}i

    unless attorney_info.nil? || attorney_info.empty?
      if attorney_info.include?('<br>')
        splitted = attorney_info.split('<br>')
      else
        splitted = attorney_info.split(';')
      end
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
      { address: (address_arr.size == 0) ? nil : address_arr.join('\n').to_s,
        city: (location_data.size == 0) ? location_data.to_s : location_data[:city].to_s,
        state: (location_data.size == 0) ? location_data.to_s : location_data[:state].to_s,
        zip: (location_data.size == 0) ? location_data.to_s : location_data[:zip].to_s
       }
    else
      { address: nil,
        city: nil,
        state: nil,
        zip: nil
       }
    end
  end

  def judgment_hash(elem)
    raw_judgment = elem.next_element.css('tr').map{|el| el.text }
    index_date = raw_judgment.find {|i| i.include?("DATE - JUDGMENT:") }.gsub("DATE - JUDGMENT:", "")
    index_amount = raw_judgment.find {|i| i.include?("AMOUNT - JUDGMENT:") }
    date_jud = Date.parse((index_date.split('/')[2] + index_date.split('/')[0] + index_date.split('/')[1])).strftime("%Y-%m-%d") rescue nil
    judgment = index_amount.split(':').last
    {
      date: date_jud,
      judgment: judgment
    }
  end 

  def description(case_type)
    description_arr = []
    @html.css("input[class='submitLink']").each do |val|
      case_id = val.attr("value").to_s.strip
      name = val.parent.next_element.children.text
      desc = val.parent.next_element.next_element.next_element.next_element.next_element.next_element.children.text
      description_arr << {
        case_id: case_id,
        name: name,
        desc:desc
      }
    end
    description_arr
  end
end
