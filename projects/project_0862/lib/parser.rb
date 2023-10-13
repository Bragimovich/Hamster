# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize
    super
  end

  def parse_main_page(doc)
    html = Nokogiri::HTML doc
    html.css("input[name='javax.faces.ViewState']").attr("value").text
  end

  def parse_list(doc)
    html = Nokogiri::HTML doc
    html.css("tbody[id='home_form:j_id_1z:tbody_element']").css('tr').map { |row| row.css('td')[0].css('a').attr("id").value }
  end

  def check_page(doc)
    html = Nokogiri::HTML doc
    html.css("div[class='col-lg-12']").css("div[style='width: 100%;']").css("div[class='col-lg-3']").empty?
  end

  def parse_page(doc)
    @html = Nokogiri::HTML doc
  end

  def data_hash
    {
      inmate: inmate,
      inmate_ids: inmate_ids,
      arrests: arrests,
      info: parse_info,
      arrests_additional: arrests_additional,
      charge: charge,
      charge_additional: parse_charge,
      bonds: parse_bonds,
      court_hearings: court_hearings,
      holding_facilities: holding_facilities,
      facilities_additional: facilities_additional,
      warrants: parse_warrants
    }
  end

  def inmate
    {
      full_name: parse_info["full_name"],
      sex: parse_info["sex"],
      race: parse_info["race"],
      birthdate: parse_info["year_of_birth"]
    }
  end

  def inmate_ids
    {
      type: "NYSID", 
      number: parse_info["nysid"]
    }
  end

  def arrests
    {
      arrest_date: parse_date(arrests_additional["arrest_date"]),
      booking_number: arrests_additional["book_&_case_number"]
    }
  end

  def charge
    unless parse_charge.empty?
      charge_arr = []
      parse_charge.each do |value|
        hash = {
          docket_number: value["docket"],
          offense_type: value["charge"]
        }
        charge_arr << hash
      end
      charge_arr
    end
  end

  def parse_bonds
    unless arrests_additional["bail_and_or_bond"].nil?
      {
        bond_type: "Bail and/or Bond",
        bond_amount: arrests_additional["bail_and_or_bond"]
      }
    end
  end

  def court_hearings
    unless parse_charge.empty?
      court_hearings_arr = []
      parse_charge.each do |value|
        hash = {
          next_court_date: parse_date(arrests_additional["next_court_date"]),
          court_name: value["court_name"],
          court_room: value["court_part"],
          case_number: value["docket"]
        }
        court_hearings_arr << hash
      end
      court_hearings_arr
    end
  end

  def holding_facilities
      {
        start_date: parse_date(arrests_additional["booking_information"]),
        actual_release_date: parse_date(arrests_additional["actual_release_date"])
      }
  end

  def facilities_additional
    unless arrests_additional["discharge_reason"].nil?
      {
        key: "discharge_reason",
        value: arrests_additional["discharge_reason"]
      }
    end
  end

  def parse_date(date)
    Date.parse(date).strftime("%Y-%m-%d") rescue nil
  end

  def parse_warrants
    unless @html.css("tbody[id='home_form:j_id_1w_5s:tbody_element']").nil?
      warrants_arr = []
      @html.css("tbody[id='home_form:j_id_1w_5s:tbody_element']").css('tr').each do |value|
        hash = {
          warrant_id: value.css('td')[0].text,
          warrant_type: value.css('td')[1].text,
          offense_type: value.css('td')[2].text,
          crime_class: value.css('td')[3].text
        }
        warrants_arr << hash
      end
      warrants_arr
    end
  end

  def parse_info
    hash = Hash.new
    @html.css("div[class='col-lg-12']").css("div[style='width: 100%;']").css("div[class='col-lg-3']").css("div[class='row']").each_with_index do |value, index|
      hash.merge!({"full_name" => value.css("div[class='col-sm-12 headerLabel']").text.strip}) if index == 0
      hash[value.css("div[class='col-sm-4 labelTd']").text.strip.downcase.gsub(":","").gsub(" ","_")] = value.css("div[class='col-sm-8 labelTdValue']").text.strip  unless index == 0
    end
    hash
  end

  def arrests_additional
    main_hash = Hash.new
    @html.css("div[class='col-lg-12']").css("div[style='width: 100%;']").css("div[class='col-lg-8']").css("div[class='row']").each_with_index do |value, index|
      hash = Hash.new
      hash[value.css("div[class='col-sm-4 headerLabel']").text.strip.downcase.gsub(":","").gsub(" ","_")] = value.css("div[class='col-sm-8 headerLabel']").text.strip.split(" ").last  if index == 0
      hash[value.css("div[class='col-sm-4 labelTd']").text.strip.downcase.gsub(":","").gsub(" ","_").gsub("/","_")] = value.css("div[class='col-sm-8 labelTdValue']").text.strip  unless index == 0
      main_hash.merge!(hash) 
      break if value.next_element.text.strip == "Charge Information" rescue nil
    end
    main_hash
  end

  def parse_charge
    check_value = false
    arr = Array.new
    main_hash = Hash.new
    @html.css("div[class='col-lg-12']").css("div[style='width: 100%;']").css("div[class='col-lg-8']").css("div[class='row']").each_with_index do |value, index|
      check_value = true if value.css("div[class='col-sm-12 headerLabel']").text.strip == "Charge Information"
      if check_value
        hash = Hash.new
        hash[value.css("div[class='col-sm-4 labelTd']").text.strip.downcase.gsub(":","").gsub(" ","_")] = value.css("div[class='col-sm-8 labelTdValue']").text.strip  unless value.css("div[class='col-sm-8 labelTdValue']").text.strip.empty?
        main_hash.merge!(hash)
        arr << main_hash if value.next_element.name == "hr" rescue nil
        main_hash = {} if value.next_element.name == "hr" rescue nil
      end
    end
    arr
  end
end
