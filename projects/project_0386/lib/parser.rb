# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize(doc)
    @html = Nokogiri::HTML(doc.force_encoding(Encoding::ISO_8859_1))
  end

  def lawyers_list
    @html.css('tbody').css('tr').map do |link|
      {
        url: link.attr("onclick").gsub("location.href=", "").gsub("'", ""),
        city: link.css('td')[2].text.gsub(" ", "_").gsub("'", "").gsub("-", "_").gsub(",", "")
      }
    end
  end

  def lawyer_data(city)
    content = @html.css('.whiteheader')
    name = content.css('.adminheader').text rescue nil
    bar_number = content.xpath('//td[@id="mnum"]').text rescue nil
    registration_status = content.xpath('//td[@id="mstatus"]').text rescue nil
    law_firm_name = content.at("td:contains('Company')").next_element.children.to_s.gsub("&amp;", "&") rescue nil
    date = content.xpath('//td[@id="madmitdate"]').text.split("/") rescue nil
    date_admited = Date.parse(date[2] + "-" + date[0] + "-" + date[1]).strftime("%Y-%m-%d") rescue nil
    raw_address = content.at("td:contains('Mailing Address')").next_element.inner_html rescue nil
    #raw_address = mailing_address#.gsub("<td class=\"coltext\">","").gsub("</td>", "").split('<br>').join(",")
    law_firm_city = city.gsub("_"," ")
    law_firm_county = content.at("td:contains('County')").next_element.children.text rescue nil
    phone = content.at("td:contains('Phone')").next_element.children.text.size < 5 ? nil : content.at("td:contains('Phone')").next_element.children.text rescue nil
    fax = content.at("td:contains('Fax')").next_element.children.text.size < 5 ? nil : content.at("td:contains('Fax')").next_element.children.text rescue nil
    email = content.at("td:contains('Email')").next_element.children.text.split.join.size < 5 ? nil : content.at("td:contains('Email')").next_element.children.text.split.join rescue nil
    law_firm_website = content.at("td:contains('Website')").next_element.children.text.split.join.size < 5 ? nil : content.at("td:contains('Website')").next_element.children.text.split.join rescue nil
    data_source_url = "https://www.osbar.org/members/membersearch_display.asp?b=#{bar_number}"

   {
      name: name,
      bar_number: bar_number,
      registration_status: registration_status,
      law_firm_name: law_firm_name,
      date_admited: date_admited,
      raw_address: raw_address,
      law_firm_city: law_firm_city,
      law_firm_county: law_firm_county,
      law_firm_website: law_firm_website,
      phone: phone,
      fax: fax,
      email: email,
      data_source_url: data_source_url
    }
  end
end
