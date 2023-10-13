# frozen_string_literal: true

class Parser < Hamster::Parser

  def get_links(html)
    page = Nokogiri::HTML(html)
    array = []
    page.css('table tr').each_with_index do |link,index|
      next if index==0
      array << link.css('td')[4].text
    end
    array
  end

  def get_parsed_content(record, html, run_id)
    page      = Nokogiri::HTML(html)
    titles    = page.css("#Div_Search_A4 tr.Search_Header td").map{|e| e.text.downcase.strip}
    values    = page.css("#Div_Search_A4 tr.Search_Text td").map{|e| e.text.strip}
    data_hash = {}
    data_hash["name"]                 = page.css('tr.Search_Text td')[0].text.squish
    data_hash["bar_number"]           = record[-1]
    data_hash["law_firm_name"]        = search_value(titles, values, "firm name").squish
    data_hash["law_firm_address"]     = search_value(titles, values, "business address")
    data_hash["phone"]                = search_value(titles, values, "phone").squish
    data_hash["fax"]                  = search_value(titles, values, "fax").squish
    data_hash["disciplinary_history"] = get_hash(page).to_json
    data_hash["date_admitted"]        = page.css('span.Home_Content_Body').text.squish
    data_hash["date_admitted"]        = DateTime.strptime(data_hash["date_admitted"], '%m/%d/%Y').to_date
    data_hash["registration_status"]  = record[-2]
    data_hash["private_practice"], data_hash["professional_liability_insurance"] = get_insurance_data(page)
    data_hash["md5_hash"]             = create_md5_hash(data_hash)
    data_hash["first_name"]           = record[1]
    data_hash["middle_name"]          = record[2]
    data_hash["last_name"]            = record[0]
    data_hash["link"]                 = "https://www.coloradosupremecourt.com/Search/Attinfo.asp?Regnum=#{data_hash["bar_number"]}"
    data_hash["run_id"]               = run_id
    data_hash = mark_empty_as_nil(data_hash)
    data_hash
  end

  def get_outer_data(html)
    page = Nokogiri::HTML(html)
    array = []
    page.css('table tr').each_with_index do |link,index|
      next if index==0
      record = link.text.split("\r\n").map{|s| s.squish}
      record.delete_at(0)
      record.delete_at(-1)
      array << record
    end
    array
  end

  private

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == "null") ? nil : value}
  end
  
  def get_hash(page)
    if page.css("#Discipline tr.Search_Header td").children.count == 0
      return nil
    end
    array  = []
    titles = page.css("#Discipline tr.Search_Header td").map{|e| e.text.downcase.strip}
    values = page.css('table.Home_Content_Body tr')[1].css('td').map{|e| e.text.strip}
    page.css('table.Home_Content_Body tr').each_with_index do |values,index|
      next if index== 0
      values = values.css('td').map{|e| e.text.strip}
      data_hash = {}
      titles.each_with_index do |title, title_index|
        data_hash[title] = values[title_index]
      end
      array << data_hash
    end
    array
  end

  def get_insurance_data(page)
    private_practice = 0
    insurance = 0
    if page.css('#Div_Search_A3 tr.Search_Text_Centered td').children.count == 0
      return [private_practice, insurance]
    end

    if page.css('#Div_Search_A3 tr.Search_Text_Centered td')[0].text =="Yes"
      private_practice = 1
    end

    if page.css('#Div_Search_A3 tr.Search_Text_Centered td')[1].text =="Yes"
      insurance = 1
    end
    [private_practice, insurance]
  end

  def get_address_values(address)
    city = nil
    zip = nil
    state = nil
    if address == nil
      return [city, zip, state]
    end
    last_line     = address.split("\n").last
    address_split = last_line.split(',').reject{|s| s == ""}
    city          = address_split[0]
    if address_split.count > 1
      zip   = address_split.last.squish.scan(/\d+-*+\d*/).first
      state = address_split.last.squish.split(' ').first
    end
    [city, zip, state]
  end

  def search_value(titles, values, word)
    value = nil
    titles.each_with_index do |title, idx|
      if title == 'business address'
        value = values[idx].squish
        if value == ""
          return nil
        end
        (idx+1..values.count-1).each do |index|
          value = "#{value}\n#{values[index].squish}"
        end
      elsif title == word
        value  = values[idx]
        break
      end
    end
    value = nil if (value == " ") || (value == "")
    value
  end
end
