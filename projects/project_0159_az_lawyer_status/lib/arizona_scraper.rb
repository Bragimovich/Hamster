# frozen_string_literal: true

require_relative '../models/arizona'

class Scraper <  Hamster::Scraper
  MAIN_URL = "https://azbar.legalserviceslink.com"

  def initialize
    super
    @proxy_filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @proxy_filter.ban_reason = proc {|response| ![200, 304].include?(response.status) || response.body.size.zero?}
    @inserted_records = Arizona.pluck(:link)
  end
  
  def connect_to(url)
    retries = 0
    begin
      response = Hamster.connect_to(url: url , proxy_filter: @proxy_filter)
      retries += 1
    end until response&.status == 200 or retries == 10
    response
  end

  def main
    page_no = 1
    while true
      data_source_url = MAIN_URL + "/lawyers/search/page:" + page_no.to_s
      response = connect_to(data_source_url)
      document = Nokogiri::HTML(response.body)
      break if document.css("section h2").first.text.include? "Not Found"
      current_page_lawyers = document.css(".row.clearfix li")
      lawyer_data_array = []
      current_page_lawyers.each do |lawyer|
        link =  MAIN_URL + lawyer.css("h3 a")[0]["href"]
        next if @inserted_records.include? link
        name = lawyer.css("h3 a").text.strip
        lawyer_data = lawyer.css(".oldRecord").first.text.split("|").map{|e| e.gsub("Member Since:","").strip}
        lawyer_data_hash = inner_page(name,link,lawyer_data,data_source_url)
        lawyer_data_array.push(lawyer_data_hash)
      end
      Arizona.insert_all(lawyer_data_array) if !(lawyer_data_array.empty?)
      page_no += 1
    end
  end

  def inner_page(name,link,lawyer_data,data_source_url)
    response = connect_to(link)
    document = Nokogiri::HTML(response.body)

    date_admitted = DateTime.strptime(lawyer_data[-1] , "%m/%d/%Y").to_date rescue nil
    registration_status = lawyer_data[0]
    contact_info = document.css(".hlfWidtleft").select{|e| e.text.include? "Contact Information"}
    law_firm_address,phone, email, law_firm_name = contact_info_parser(contact_info)

    law_firm_county = document.css(".rightli").select{|e| !(e.css("span.glyphicon-map-marker").empty?)}.first.text.strip.split(",").select{|e| e.include? "County"}.first.strip rescue nil
    law_firm_state = document.css(".rightli").select{|e| !(e.css("span.glyphicon-map-marker").empty?)}.first.text.strip.split(",").reject{|e| if !(law_firm_county.nil?) then e.include? law_firm_county end}[-1].strip  rescue nil
    type = document.css(".jobAppDetailTP h4")[0].text.strip  rescue nil
    sections_temp = document.css(".jobAppDetailBT div").select{|e| e.css("h4").text.include? "Areas of Law and Practice"}.first.css(".areaLaw").map{|e| e.text.strip}.join(", ").strip  rescue nil
    sections = sections_temp == "" ? nil : sections_temp
 
    lawyer_data_hash = {
      name: name,
      link: link,
      date_admitted: date_admitted,
      registration_status: registration_status,
      type: type,
      law_firm_name: law_firm_name,
      law_firm_address: law_firm_address,
      law_firm_county: law_firm_county,
      law_firm_state: law_firm_state,
      phone: phone,
      email: email,
      data_source_url: data_source_url,
      sections: sections,     
    }
    lawyer_data_hash
  end

  def contact_info_parser(contact_info)
    law_firm_address,phone, email, law_firm_name = nil 
    if contact_info != [] 
      if !(contact_info.first.text.include? "No Contact Information")
        non_href = contact_info[0].css("p").to_s.scan(/(?:<*>)([\s\S]*?)(?=<br>)/).map{|e| e[0].strip}.reject{|e| e.include? "<a href"}
        law_firm_address = contact_info[0].css("a").select{|e| !(e.text.include? "http")}.first.text.strip  rescue nil
        phone = non_href.select{|e| e.scan(/\d+-\d+-\d+/) != []}.first
        email = non_href.select{|e| e.scan(/\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/) != []}.first
        law_firm_name = non_href.reject{|e| if !(email.nil?) then e.include? email end  or if !(phone.nil?) then e.include? phone end}.first.strip rescue nil
      end
    end
    return [law_firm_address,phone, email, law_firm_name]
  end
end
