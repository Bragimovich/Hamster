# frozen_string_literal: true

class Parser < Hamster::Scraper

  def get_access_token(response)
    data = Nokogiri::HTML(response.body)
    data_hash = {}
    data_hash = {
      data_sitekey: data.xpath("//div[@class='g-recaptcha']//@data-sitekey").first.content,
      token: data.xpath("//input[@name='__RequestVerificationToken']//@value")[0].content
    }
    return data_hash
  end

  def get_offenders(response)
    fetch_json(response.body)["ids"]
  end


  def parse_offender(file, run_id)
    data_hash = {}
    begin
      parsed_data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end
    age = calculate_age(Date.parse(parsed_data["offender"]["DateOfBirth"]))
    of_data = parsed_data["offender"]
    data_hash = {
      full_name: of_data["Name"]["FriendlyName"],
      first_name: of_data["Name"]["FirstName"],
      middle_name: of_data["Name"]["MiddleInitial"],
      last_name: of_data["Name"]["LastName"],
      suffix: of_data["Name"]["SuffixName"],
      birthdate: of_data["DateOfBirth"],
      age: age,
      race: of_data["Race"],
      sex: of_data["Gender"],
      height: of_data["Height"],
      weight: of_data["Weight"],
      eye_color: of_data["EyeColor"],
      hair_color: of_data["HairColor"],
      skin_color: of_data["SkinColor"],
      data_source_url: "https://sexoffender.dsp.delaware.gov/?/Detail/#{of_data["Id"]}"
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash
  end

  def parse_marks(file, run_id, arrestee_id)
    hash_array = []
    begin
      parsed_data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end
    parsed_data["offender"]["ScarsMarksTattoos"].each do |mark|
      data_hash = {}
      data_hash = {
        arrestee_id: arrestee_id,
        type_marks: mark["Key"],
        description: mark["Value"],
        data_source_url: "https://sexoffender.dsp.delaware.gov/?/Detail/#{parsed_data["offender"]["Id"]}"
      }
      data_hash = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      data_hash[:run_id] = run_id
      hash_array << data_hash
    end
    hash_array
  end

  def parse_arrestee_aliases(file, run_id, arrestee_id)
    hash_array = []
    begin
      parsed_data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end

    parsed_data["offender"]["Aliases"].each do |alia|
      data_hash = {}
      data_hash = {
        arrestees_id: arrestee_id,
        alias_full_name: alia["FriendlyName"],
        alias_first_name: alia["FirstName"],
        alias_middle_name: alia["MiddleInitial"],
        alias_last_name: alia["LastName"],
        alias_suffix: alia["SuffixName"],
        data_source_url: "https://sexoffender.dsp.delaware.gov/?/Detail/#{parsed_data["offender"]["Id"]}"
      }
      data_hash = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      data_hash[:run_id] = run_id
      hash_array << data_hash
    end
    hash_array
  end

  def parse_reg_information(file, run_id, arrestee_id)
    data_hash = {}
    begin
      data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end
    parsed_data = data["offender"]
    verifyon = Date.parse(parsed_data["VerifiedDate"]).strftime("%Y-%m-%d") rescue nil
    registered_since = Date.parse(parsed_data["RegisteredSince"]).strftime("%Y-%m-%d") rescue nil
    data_hash = {
      arrestees_id: arrestee_id,
      resk_level: check_risk(parsed_data["RiskLevel"]),
      verified_on: verifyon,
      registered_since: registered_since,
      in_priston: parsed_data["InPrison"],
      repeate_offender: parsed_data["RepeatOffender"],
      convicted_out_state: parsed_data["ConvictedOutOfState"],
      data_source_url: "https://sexoffender.dsp.delaware.gov/?/Detail/#{data["offender"]["Id"]}"
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash
  end

  def parse_mugshots(file, run_id, arrestee_id)
    data_hash = {}
    begin
      data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end
    link = "https://sexoffender.dsp.delaware.gov/Image/Download/#{data["offender"]["Id"]}"
    aws_link = save_to_aws(link,data["offender"]["Id"])
    data_hash = {
      arrestees_id: arrestee_id,
      aws_link: aws_link,
      original_link: link,
      data_source_url: "https://sexoffender.dsp.delaware.gov/?/Detail/#{data["offender"]["Id"]}"
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash
  end

  def save_to_aws(link, id)
    aws_s3 = AwsS3.new(:hamster, :hamster)
    key_start = "sex_offenders_mugshots/delaware/usa/"
    cobble = Dasher.new(:using=>:cobble, ssl_verify: false)
    body = cobble.get(link)
    file_name = id
    key = key_start + file_name + ".jpg"
    aws_link = aws_s3.put_file(body, key, metadata={ url: link })
    puts "  [+] PHOTO LOAD IN AWS!".green
    aws_link
  end

  def get_address_list(file)
    begin
      data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end
    return data["offender"]["Addresses"]
  end

  def parse_state(address)
    if !address["State"].nil?
      data_hash = {}
      data_hash = {
        name: address["State"]
      }
      data_hash = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      return data_hash
    else
      return nil
    end
  end

  def parse_city(address, state_id)
    if !address["City"].nil?
      return nil if address["City"] == "UNKNOWN"
      data_hash = {}
      data_hash = {
        name: address["City"],
        state_id: state_id
      }
      data_hash = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      return data_hash
    else
      return nil
    end
  end

  def parse_zip(address)
    if !address["Zip"].nil?
      data_hash = {}
      data_hash = {
        code: address["Zip"]
      }
      data_hash = mark_empty_as_nil(data_hash)
      md5_hash = MD5Hash.new(columns: data_hash.keys)
      md5_hash.generate(data_hash)
      data_hash[:md5_hash] = md5_hash.hash
      return data_hash
    else
      return nil
    end
  end

  def parse_address(address, run_id, arrestee_id, state_id, city_id, zip_id, file)
    begin
      data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end
    data_hash = {}
    data_hash = {
      full_address: prepare_address(address),
      cities_id: city_id,
      zips_id: zip_id,
      states_id: state_id,
      coordinates_id: '',
      data_source_url: "https://sexoffender.dsp.delaware.gov/?/Detail/#{data["offender"]["Id"]}"
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash
  end

  def prepare_address(add)
    [add["StreetNumber"],
    add["StreetPrefix"],
    add["AddressLine2"],
    add["StreetName"],
    add["StreetType"],
    add["City"],",",
    add["State"],
    add["Zip"]].join(" ").strip()
  end

  def arrestee_address(run_id, add_id, address, file, arrestee_id)
    data_hash = {}
    data_hash = {
      addresses_id: add_id,
      arrestees_id: arrestee_id,
      type_address: address["Type"]
    }
    if address["Type"] == "Work"
      data_hash[:employer] = address["Comments"]
    else
      data_hash[:employer] = nil
    end
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash
  end

  def get_vehical_list(file)
    begin
      parsed_data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end
    parsed_data["offender"]["Vehicles"]
  end

  def parse_vehicles(vehical, state_id, arrestee_id, run_id, file)
    begin
      data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end
    data_hash = {}
    data_hash = {
      arrestee_id: arrestee_id,
      type_vehicles: vehical["Type"],
      make: vehical["Make"],
      model: vehical["Model"],
      color: vehical["Color"],
      registration: vehical["Tag"],
      state_id: state_id,
      data_source_url: "https://sexoffender.dsp.delaware.gov/?/Detail/#{data["offender"]["Id"]}"
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash[:run_id] = run_id
    data_hash
  end

  def get_convictions(file)
    begin
      parsed_data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end
    parsed_data["offender"]["Arrests"]
  end

  def parse_convictions(convictions, state_id, arrestee_id, file)
    begin
      data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end
    data_hash = {}
    date = Date.parse(convictions["AdjudicationDate"]).strftime("%Y-%m-%d") rescue nil
    data_hash = {
      arrestee_id: arrestee_id,
      date: date,
      description: convictions["Description"],
      statute: convictions["Statute"],
      victims_age: convictions["VictimAge"],
      state_id: state_id,
      data_source_url: "https://sexoffender.dsp.delaware.gov/?/Detail/#{data["offender"]["Id"]}"
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash
  end

  def get_agency_address(file)
    begin
      parsed_data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end
    parsed_data["offender"]["PoliceAgency"]["Address"]
  end

  def parse_agency(run_id, add_id, file, arrestee_id)
    begin
      parsed_data = fetch_json(file)
    rescue StandardError => e
      return data_hash
    end
    data = parsed_data["offender"]["PoliceAgency"]
    data_hash = {}
    data_hash = {
      name: data["Name"],
      type_agency: "",
      subtype: "",
      phone: data["Phone"],
      addresses_id: (add_id.nil?) ? "": add_id,
      data_source_url: "https://sexoffender.dsp.delaware.gov/?/Detail/#{parsed_data["offender"]["Id"]}"
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash
  end

  def parse_arrestee_agency(run_id, agency_id, arrestee_id)
    data_hash = {}
    data_hash = {
      arrestees_id: arrestee_id,
      agencies_id: agency_id,
    }
    data_hash = mark_empty_as_nil(data_hash)
    md5_hash = MD5Hash.new(columns: data_hash.keys)
    md5_hash.generate(data_hash)
    data_hash[:md5_hash] = md5_hash.hash
    data_hash
  end

  def check_risk(risk)
    if risk == 1
      return "Tier 1 (Low Risk)"
    elsif risk == 2
      return "Tier 2 (Moderate Risk)"
    elsif risk == 3
      return "Tier 3 (High Risk)"
    else
      return risk
    end
  end

  def fetch_json(response)
    JSON.parse(response)
  end
  private

  def calculate_age(birthdate)
    today = Date.today
    age_in_days = (today - birthdate).to_i
    age_in_years = age_in_days / 365.25
    return age_in_years.floor
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values { |value| value.to_s.empty? || value == 'null' ? nil : value }
  end
end
