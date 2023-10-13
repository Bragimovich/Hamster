# frozen_string_literal: true

class Parser < Hamster::Parser
  
  def get_links(doc)
    links = []
    doc.css('#MainContent_gvSearchResults tr').each do |row_tag|
      next if row_tag.css('td').length == 0
      next if row_tag.css('td')[3].text.include?("Assumed Name")
      href = row_tag.at_css('td a')['href']
      if href =~  /^Profile.aspx/
        href = "https://web.sos.ky.gov/bussearchnprofile/" + href
      end
      links << href
    end
    links
  end
  
  def parse_detail(doc)
    detail_obj = {}

    doc.css('#MainContent_pInfo table tr.Activebg').each do |e|
      e.css('br').each{ |br| br.replace("\n") }
      detail_obj[e.css('td')[1].text.strip.underscore.split(' ').join('_')] = e.css('td')[2].text.strip
    end
    (detail_obj["principal_office_address"], detail_obj["principal_office_city_state_zip"]) = detail_obj["principal_office"].split("\n", 2) rescue [nil, nil]
    detail_obj.delete("principal_office")
    detail_obj["status"] = detail_obj["status"].split('-')[-1].strip rescue nil
    detail_obj["standing"] = detail_obj["standing"].split('-')[-1].strip rescue nil
    if detail_obj["profit_or_non_profit"]
      if detail_obj["profit_or_non_profit"].include?('Non-profit')
        detail_obj["is_profit_org"] = "<FALSE>"
      else
        detail_obj["is_profit_org"] = "<TRUE>"
      end
    else
      detail_obj["is_profit_org"] = nil
    end

    detail_obj.delete("profit_or_non_profit")
    
    detail_obj["business_name"] = detail_obj["name"] rescue nil
    detail_obj.delete("name")

    # TODO pase address, zip
    
    officers_detail_array = []
    doc.css('#MainContent_PnlOfficers table tr').each do |e|
      next if e.css('td').size == 0
      hash = {}
      hash["role"] = "Current " + e.xpath('.//span[contains(@id, "MainContent_GvOff_LblTitle")]').text.strip
      hash["name"] = e.xpath('.//a[contains(@id, "MainContent_GvOff_LbOfficer")]').text.strip
      officers_detail_array <<  hash
    end

    doc.css('#MainContent_PnlIOff table tr').each do |e|
      next if e.css('td').size == 0
      hash = {}
      hash["role"] = "Initial " + e.xpath('.//span[contains(@id, "MainContent_GvIOff_LblTitle")]').text.strip
      hash["name"] = e.xpath('.//a[contains(@id, "MainContent_GvIOff_LbOfficer")]').text.strip
      officers_detail_array <<  hash
    end
    { general: detail_obj, officers: officers_detail_array }
  end

end
