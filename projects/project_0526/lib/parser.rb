class Parser
  def get_required_form_data_variables(file_content)
    data = Nokogiri::HTML(file_content)
    {
      manager: "ctl01$TemplateBody$WebPartManager1$gwpciLawyerDirectory$ciLawyerDirectory$ResultsGrid$Sheet0$SubmitButton",
      view_state: data.css("#__VIEWSTATE")[0]["value"],
      view_state_gen: data.css("#__VIEWSTATEGENERATOR")[0]["value"],
      page_instance_key: data.css("#PageInstanceKey")[0]["value"],
      request_verification_token: data.css("#__RequestVerificationToken")[0]["value"],
      client_context: data.css("#__ClientContext")[0]["value"],
      script_manager_tsm: get_script_manager_tsm(file_content)
    }
  end

  def get_required_form_data_variables_v2(file_content)
    data = Nokogiri::HTML(file_content)
    {
      view_state: file_content.split("|__VIEWSTATE|")[-1].split("|")[0],
      view_state_gen: file_content.split("|__VIEWSTATEGENERATOR|")[-1].split("|")[0],
      client_context: file_content.split("|__ClientContext|")[-1].split("|")[0],
      request_verification_token: file_content.split("|__RequestVerificationToken|")[-1].split("|")[0],
      page_instance_key: file_content.split("|PageInstanceKey|")[-1].split("|")[0],
      script_manager_tsm: URI.decode(file_content.split("|ScriptPath|")[-1].split("|")[0])
    }
  end

  def check_for_records_limit(file_content)
    data = Nokogiri::HTML(file_content)
    xpath = "//div[@class='rgWrap rgInfoPart']"
    res = data.xpath(xpath)
    more_records_available = res&.first&.text&.strip&.include?("of 250")
    more_records_available
  end


  def get_link_of_all_data(file_content)
    data = Nokogiri::HTML(file_content)
    xpath = "//a[@class='AddPaddingLeft']"
    data.xpath(xpath)
  end

  def parse_all_data_div(link_div)
    link_div.values[-1].split("'")[1]
  end

  def get_each_user_data(file_content)
    if file_content.include?("There are no records")
      return []
    end
    data = Nokogiri::HTML(file_content)
    xpath = "//table//tbody/tr"
    data.xpath(xpath)
  end
  
  def get_user_hash(tr_div)
    {
      name: tr_div.children[1].xpath("a").attribute('title')&.value,
      link: tr_div.children[1].xpath("a").attribute('href')&.value,
      city: tr_div.children[2]&.text,
      zip: tr_div.children[3]&.text,
      status: tr_div.children[4]&.text,
    }
  end

  def parse_user_page(file_content)
    data = Nokogiri::HTML(file_content)
    xpath = "//div[@class='ReadOnly PanelField Left']"
    rows = data.xpath(xpath)
    hash = {}
    rows.each do |row|
      key, value = row.elements
      key = key.text.strip

      if key.include?("Name")
        name = value&.text&.strip&.gsub("*","")
        hash[:name] = name
        splits = name.split()
        if splits.length == 2
          # no middle name
          hash[:last_name] = splits[0]&.gsub(",","")
          hash[:first_name] = splits[1]&.gsub(",","")
        else
          hash[:last_name] = splits[0]&.gsub(",","")
          hash[:middle_name] = splits[1]&.gsub(",","")
          hash[:first_name] = splits[2]&.gsub(",","")
        end
      end
      
      if key.include?("Bar Number")
        hash[:bar_number] = value.text.strip
      end

      if key.include?("Date Admit")
        date = value&.text&.strip
        if date.present?
          hash[:date_admited] = Date.strptime(date, "%m/%d/%Y").to_date.to_s
        end
      end

      if key.include?("Location")
        address = value.text.strip
        hash[:law_firm_address] = address
        hash[:law_firm_zip] = address&.match(/\d{3,}/)&.to_s
        city, state_and_zip = address.split(",")
        hash[:law_firm_city] = city
        hash[:law_firm_state] = state_and_zip&.strip&.split(" ")&.first
      end

      if key.include?("Current Standing")
        hash[:registration_status] = value.text.strip
      end
    end
    hash
  end

  private

  def get_script_manager_tsm(body)
    str = "/Telerik.Web.UI.WebResource.axd?_TSM_HiddenField_="
    end_str = 'type="text/javascript"></script>'
  
    unless body.index(str).nil?
      temp = body[body.index(str) + str.length..-1]
      _pub = temp.split(end_str)[0].gsub(" ","").gsub("\"",'')
      remove_str = 'ctl01_ScriptManager1_TSM&amp;compress=1&amp;_TSM_CombinedScripts_='
      pub = URI.decode(_pub)
      pub[remove_str] = ""
      return pub
    end
    nil
  end
end