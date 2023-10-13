# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize(hash)
    super
    @hash = hash
    parse_info_hash
  end

  def parse_info
    {
      full_name: parse_name,
      first_name: @info_hash["First_Name"],
      middle_name:  parse_value(@info_hash["Middle_Name"]),
      last_name: @info_hash["Last_Name"],
      suffix: parse_value(@info_hash["Suffix"]),
      birthdate: parse_date(@info_hash["Birth_Date"]),
      sex: @info_hash["Sex"],
      race: @info_hash["Race"],
      height: @info_hash["Height"].gsub("\"",""),
      weight: @info_hash["Weight"],
      hair_color: @info_hash["Hair_Color"],
      eye_color: @info_hash["Eye_Color"],
      age: @info_hash["Current_Age"],
      original_link: @hash[:img],
      tables: parse_charge_arr
    }
  end

  def parse_charge_arr
    unless @hash["charges"].empty?
      arrests_arr = []
      charges_arr = []
      bonds_arr = []
      court_arr = []
      @hash["charges"].each do |row|
        row.each do |key, str|
          value = parse_value(str)
          @status = value if key == "chargeStatus"
          @arrest_date = parse_time(value).first if key == "arrestDate"
          @booking_date = parse_booking_date(@info_hash["Booking_Date"]).join(' ')
          @booking_agency = value if key == "arrestingAgency"
          @description = value if key == "chargeDescription"
          @offense_type = value if key == "crimeType"
          @offense_date = parse_time(value).first if key == "offenseDate"
          @counts = value if key == "counts"
          @bond_category = value if key == "modifier"
          @bond_type = value if key == "bondType"
          @bond_amount = value if key == "bondAmount"
          @made_bond_release_date = parse_booking_date(@info_hash["Date_Released"]).first
          @made_bond_release_time = parse_booking_date(@info_hash["Date_Released"]).last
          @court_name = value if key == "courtName"
          @court_date = parse_time(value).first if key == "courtTime"
          @court_time = parse_time(value).last if key == "courtTime"
          @case_number = value if key == "caseNo"
          @sentence_type = value if key == "courtType"
        end
        arrests_arr << {
          status: @status,
          arrest_date: @arrest_date,
          booking_date: @booking_date,
          booking_agency: @booking_agency
        }
        charges_arr << {
          description: @description, 
          offense_type: @offense_type,
          offense_date: @offense_date,
          counts: @counts
        }
        bonds_arr << {
          bond_category: @bond_category, 
          bond_type: @bond_type,
          bond_amount: @bond_amount,
          made_bond_release_date: @made_bond_release_date,
          made_bond_release_time: @made_bond_release_time
        }
        court_arr << {
          court_name: @court_name,
          court_date: @court_date,
          court_time: @court_time,
          case_number: @case_number,	
          sentence_type: @sentence_type
        }
      end
      [arrests_arr ,charges_arr ,bonds_arr ,court_arr]
    end
  end

  def parse_info_hash
    @info_hash = Hash.new
    @hash["offenderSpecialFields"].each do |row|
      @info_hash[(row["labelText"]).gsub(":","").split(' ').join("_")] = row["offenderValue"]
    end
  end

  def parse_booking_date(date)
    split_date = date.split(" ") rescue nil
    raw_date = split_date.first.split('/') rescue nil
    day = Date.parse((raw_date[2] + (format('%02d', raw_date[0]) rescue raw_date[0]) + raw_date[1])).strftime("%Y-%m-%d") rescue nil
    time = Time.parse(split_date[1..2].join).strftime("%H:%M:%S") rescue nil
    [day, time]
  end

  def parse_name
    [
      parse_value(@info_hash["First_Name"]),
      parse_value(@info_hash["Middle_Name"]),
      parse_value(@info_hash["Last_Name"]),
      parse_value(@info_hash["Suffix"])
    ].compact.join(" ")
  end

  def parse_value(data)
    data = data.strip unless data.nil?
    data.nil? || data.empty? ? nil : data
  end

  def parse_date(date)
    raw_date = date.split("/") rescue nil
    Date.parse((raw_date[2] + (format('%02d', raw_date[0]) rescue raw_date[0]) + raw_date[1])).strftime("%Y-%m-%d") rescue nil
  end

  def parse_time(date)
    day = Date.parse(date).strftime("%Y-%m-%d") rescue nil
    time = Time.parse(date).strftime("%H:%M:%S") rescue nil
    [day, time]
  end
end
