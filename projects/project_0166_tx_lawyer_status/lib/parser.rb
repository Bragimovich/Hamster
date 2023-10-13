# frozen_string_literal: true

class Parser < Hamster::Parser

  def parsed_html(response)
    Nokogiri::HTML(response.force_encoding("utf-8"))
  end

  def get_last_page(response)
    body = parsed_html(response)
    body.css(".pagenumber").last.css("a").text.to_i
  end

  def get_links(response)
    url   = "https://www.texasbar.com"
    body  = parsed_html(response)
    body.css("h3 a").map{|a| url + a["href"]}
  end

  def get_states(html)
    body = parsed_html(html)
    body.css("#State option").map{|a| a["value"]}
  end

  def parser(html, link, run_id)
    body                   = parsed_html(html)
    bar_number             = body.css("#hcard-Lawyer-L-Name p").select{|e| e.text.include? "Bar Card Number:"}.first.text.squish.gsub("Bar Card Number:","").gsub("TX License Date:","").strip.split rescue nil
    full_name              = body.css("h3 span").map{|e| e.text}.reject{|e| e == ""}.join(" ").split("\r")
    date                   = bar_number[1] rescue nil
    practise_location      = body.css("div#hcard-Lawyer-L-Name p")[-4].text.remove("Primary Practice Location:").squish rescue nil
    law_firm_address       = body.css("div#hcard-Lawyer-L-Name p.address").children[1].children.map {|e| e.text.squish}.reject{|r| r.empty?}.join("\n")
    street_address         = (law_firm_address.split("\n").count > 1)? law_firm_address.split("\n")[..-2].join("\n") : nil
    zip                    = law_firm_address.split(",")[-1].strip.split(" ") rescue nil
    state                  = law_firm_address.split(",").last.tr("0-9", "").gsub("-", "").gsub("_", "").strip rescue nil
    state = /\d/.match?(state) ? nil : state
    sections               = body.css("div#hcard-Lawyer-L-Name p")[-2].text.squish rescue nil
    profile_last_certified = body.css("div#hcard-Lawyer-L-Name p")[-1].text.remove("Statutory Profile Last Certified On:").squish rescue nil
    profile_last_certified = Date.strptime(profile_last_certified,'%m/%d/%Y') rescue nil
    law_firm_name          = body.css("div#hcard-Lawyer-L-Name h5").text
    law_firm_city          = law_firm_address.split("\n").last.split(",")[0] rescue nil
    law_firm_city = /\d/.match?(law_firm_city) ? nil : law_firm_city
    phone                  = body.css(".contact a").select{|e| e.text.include? "Tel:"}[0].text.gsub("Tel:","").strip rescue nil
    data_hash = {}
    data_hash[:phone]                       = phone == "--"? nil : phone
    data_hash[:law_firm_address]            = (law_firm_address.nil?)? law_firm_address : (law_firm_address.empty?)? law_firm_address = nil : law_firm_address
    data_hash[:street_address]              = street_address
    data_hash[:data_source_url]             = link
    data_hash[:name]                        = full_name[0].squish rescue nil
    data_hash[:status]                      = full_name[1].squish rescue nil
    data_hash[:date_admitted]               = Date.strptime(date,'%m/%d/%Y') rescue nil
    data_hash[:bar_number]                  = bar_number[0] rescue nil
    data_hash[:practise_location]           = (practise_location.nil?)? practise_location : (practise_location.empty?)? practise_location = nil : practise_location 
    data_hash[:law_firm_address]            = (law_firm_address.nil?)? law_firm_address : (law_firm_address.empty?)? law_firm_address = nil : law_firm_address
    data_hash[:sections]                    = sections.remove("Practice Areas:").squish rescue nil
    data_hash[:practise_info]               = get_json_practise_info(body)
    data_hash[:courts_of_admittance]        = get_json_courts_of_admittance(body)
    data_hash[:law_school]                  = get_law_school(body)
    data_hash[:profile_last_certified]      = profile_last_certified
    data_hash[:law_firm_name]               = (law_firm_name.nil?)? law_firm_name : (law_firm_name.empty?)? law_firm_name = nil : law_firm_name 
    data_hash[:public_disciplinary_history] = get_public_disciplinary(body)
    data_hash[:md5_hash]                    = create_md5_hash(data_hash)
    data_hash                               = mark_empty_as_nil(data_hash)
    data_hash[:law_firm_zip]                = /[a-zA-Z]/.match?(zip[1]) ? nil : zip[1] rescue nil
    data_hash[:law_firm_state]              = state
    data_hash[:law_firm_city]               = law_firm_city.squish rescue nil
    data_hash[:run_id]                      = run_id
    data_hash[:touched_run_id]              = run_id
    data_hash
  end

  private

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : value}
  end

  def get_json_practise_info(body)
    data_hash = {}
    body.css("div.practice-information p").map{|e|
      if e.text.split(":")[0].strip.include? "Services"
        data_hash[e.text.split(":")[0].strip] = e.css('text()').map(&:text).map(&:strip)[1..-1].join(", ")
      elsif e.text.include? "Fee Options Provided"
        data_hash[e.text.split(":")[0].strip] = e.text.split(":")[1].gsub('Please note','').squish
      else
        data_hash[e.text.split(":")[0].strip] = e.text.split(":")[-1].squish
      end
    }
    data_hash.to_json
  end

  def get_json_courts_of_admittance(body)
    data_hash = {}
    body.css("div.admittance p").map{|e|
      val = e.css('text()').map(&:text).map(&:squish).compact_blank
      unless val.first.include? 'Please note:'
        data_hash[val.first.gsub(':','')] = val[1..-1].join(' | ') rescue nil
      end
    }
    data_hash.to_json
  end

  def get_law_school(body)
    data_hash_list = []
    body.css("div.school tbody tr").map{ |e|
      data_hash = {}
      pp = Nokogiri::HTML(e.to_s.split('<span')[0])
      data_hash["university"] = pp.text.squish
      pp = Nokogiri::HTML(e.to_s.split('</span>')[-1])
      data_hash["graduation_date"] = pp.text.squish == "" ? nil : pp.text.squish
      data_hash_list << data_hash
    }
    data_hash_list.to_json
  end

  def get_public_disciplinary(body)
    data_hash_list = []
    headers = body.css("div.public-history table")[0].css("thead").css('th').map(&:text).compact_blank rescue nil
    return  data_hash_list.to_json if headers.nil?
    body.css("div.public-history table tbody tr").each {|row|
      data_hash = {}
      all_tds = row.css('td')
      next if all_tds.count < headers.count
      headers.each_with_index do |head, index|
        if index == 0
          data_hash[head] = all_tds[index].css('p').text.squish
        else
          data_hash[head] = all_tds[index].text.squish
        end
        data_hash[head] = data_hash[head] == "" ? nil : data_hash[head]
      end
      data_hash_list << data_hash
    }
    data_hash_list.to_json
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
