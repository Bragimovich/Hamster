class Parser < Hamster::Parser

  def get_profession(response)
    document    = Nokogiri::HTML(response.body)
    [document.css('a').map { |link| link['href'] },document.css('form[name="INPUT"]')[0].css('input[name="page"]')[0]['value'],("000-000-000" || document.css('input[name="corp"]').attr('value').value)]
  end

  def get_links(response, part)
    outer_page = Nokogiri::HTML(response.body.force_encoding("utf-8"))
    baseurl    = "https://arc-sos.state.al.us"
    link       = outer_page.at_css("form")["action"]
    last       = "?page=number&corp=#{part}"
    "#{baseurl}#{link}#{last}"
  end

  def get_inside_link(part)
    baseurl    = "https://arc-sos.state.al.us"
    link       = "/cgi/corpdetail.mbr/detail"
    last       = "?page=number&corp=#{part}"
    "#{baseurl}#{link}#{last}"
  end

  def info_parser(inner_page, link,md5_array,id)
    document = Nokogiri::HTML(inner_page)
    state_data_hash = {}
    records = document.css("tr")
    search = document.css("b").text
    if (search.empty?)
      records.each_with_index do |hash, index|
        next if index == 0
        key = hash.css("td")[0].text.downcase.strip.gsub(/\s/, "_")
        next if key.empty? or  key == "" or key == "entity_id_number"
        value = hash.css("td")[-1]&.text&.strip
        value = nil if value.empty? || value == "Not Provided"
        state_data_hash[key] = hash[key] == hash[value] || (key.length > 50 && value.length > 50) ? value : state_data_hash[key].to_a << value
        val = (val = document.css("td.aiSosDetailHead")[0]) ? val.text.strip.gsub(/\\n/, "") : nil
        state_data_hash["entity_name"] = val
        entity_id = link.split("=").last
        state_data_hash["entity_id"] = value_format(entity_id)
        state_data_hash["entity_url"] = link
        state_data_hash["run_id"] = id
        state_data_hash["on_site"] = 1
        state_data_hash["touched_run_id"] = id
        state_data_hash["last_scrape_date"] = Date.today
        state_data_hash["next_scrape_date"] = Date.today + 30
      end
      fetch_details(state_data_hash, md5_array)
    end
  end

  private

  def fetch_details(state_data_hash,md5_array)
    new_state_data_hash = {}
    state_data_hash.each do|key , value|
      state_data_hash = date_fetch(state_data_hash, key, value)
      if (key == "principal_address")
        new_state_data_hash = fetch_address_details(value, new_state_data_hash, "principal")
      elsif (key == "registered_office_street_address")
        new_state_data_hash = fetch_address_details(value, new_state_data_hash, "registered_office")
      elsif (key == "capital_authorized")
        new_state_data_hash = fetch_capital(key, value, new_state_data_hash)
      end
    end
    new_state_data_hash["md5_hash"] = create_md5_hash(new_state_data_hash) unless (new_state_data_hash.nil? ) || (new_state_data_hash.empty?)
    md5_array << new_state_data_hash["md5_hash"]
    new_state_data_hash.delete("md5_hash")
    state_data_hash = state_data_hash.merge(new_state_data_hash)
    state_data_hash = transform(state_data_hash)
    state_data_hash
  end

  def date_fetch(state_data_hash, key, value)
    unless (key != "withdrawn_date") || (key != "dissolved_date") || (key != "merged_date") || (key != "revoked_date") || (key != "formation_date") || (key != "cancelled_date")
      state_data_hash[key] = Date.strptime(value, "%m/%d/%Y").to_date rescue nil
    end
    state_data_hash
  end

  def fetch_address_details(value, new_state_data_hash, type)
    unless (value == nil)
      list = value.split(",")
      new_state_data_hash["#{type}_zip"]   = list.last.split[1][0,5] rescue nil
      new_state_data_hash["#{type}_city"]  = list.first.split.last rescue nil
      new_state_data_hash["#{type}_state"] = list.last.split.first rescue nil
    end
    new_state_data_hash
  end

  def fetch_capital(key, value, new_state_data_hash)
    unless (value == nil)
      new_state_data_hash["capital_authorized"]= value_format(value).to_i rescue nil
      new_state_data_hash["capital_paid_in"]= value_format(value).to_i rescue nil
    end
    new_state_data_hash
  end

  def transform(hashes)
    mappings = {
      "entity_id" => "entity_id",
      "entity_name"=>"entity_name",
      "entity_type"=>"entity_type" ,
      "principal_address"=>"principal_address",
      "principal_mailing_address"=>"principal_address_clean",
      "principal_state" => "principal_state",
      "principal_zip" => "principal_zip",
      "principal_city" => "principal_city",
      "status" => "status",
      "withdrawn_date" =>"withdrawn_date",
      "dissolved_date"=>"dissolved_date",
      "revoked_date"=>"revoked_date",
      "merged_date"=>"merged_date",
      "merged_into"=>"merged_into",
      "cancelled_date"=>"cancelled_date",
      "consolidated_date"=>"consolidated_date",
      "consolidated_to"=>"consolidated_to",
      "service_of_process_name"=>"service_of_process_name",
      "place_of_formation"=>"place_of_formation",
      "formation_date" => "formation_date",
      "qualify_date"=>"qualify_date",
      "registered_agent_name"=>"registered_agent_name",
      "resigned_date"=>"resigned_date",
      "registered_office_mailing_address" =>"registered_office_address",
      "registered_office_street_address"=>"registered_office_address_clean",
      "registered_office_zip"=>"registered_office_zip",
      "registered_office_city"=>"registered_office_city",
      "registered_office_state"=>"registered_office_state",
      "nature_of_business"=>"nature_of_business",
      "capital_authorized"=>"capital_authorized",
      "capital_paid_in"=>"capital_paid_in",
      "entity_url"=>"data_source_url" ,
      "run_id"=>"run_id",
      "on_site" => "on_site",
      "touched_run_id" => "touched_run_id",
      "created_by"=> "created_by",
      "deleted" => "deleted",
      "expected_scrape_frequency" => "expected_scrape_frequency",
      "last_scrape_date" => "last_scrape_date",
      "next_scrape_date" => "next_scrape_date",
      "scrape_status"=> "scrape_status"
    }
    new_hash = hashes.transform_keys { |k| mappings[k.to_s] }.compact
    new_hash.delete(nil)
    new_hash
  end

  def value_format(name_string)
    name_string.scan(/([A-Za-z0-9]+)/).flatten.join
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

end
