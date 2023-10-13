# frozen_string_literal: true

class IlDuPageParser < Hamster::Parser

  def initialize
    super

  end

  def parse_json(json_str)
    JSON.parse(json_str)
  end

  def parse_arrestee(inmate)
    inmate_info = {
      full_name: "#{inmate["LastName"]}, #{inmate["FirstName"]}",
      first_name: inmate["FirstName"].presence,
      last_name: inmate["LastName"].presence,
      race: inmate["Race"].presence,
      sex: inmate["Gender"].presence,
      height: inmate["Height"].presence,
      weight: inmate["Weight"].presence,
      mugshot: inmate["ImageUrl"].include?("inmate-placeholder.png") ? nil : inmate["ImageUrl"],
      data_source_url: inmate["InmateId"] && "https://search.dupagesheriff.org/inmate/details/#{inmate["InmateId"]}"
    }
    inmate_info[:md5_hash] = calc_md5_hash(inmate_info)
    inmate_info
  end

  def parse_mugshot(inmate, arrestee_id, mugshot_aws_url)
    mugshot = {
      arrestee_id: arrestee_id,
      aws_link: mugshot_aws_url,
      original_link: inmate["ImageUrl"].include?("inmate-placeholder.png") ? nil : inmate["ImageUrl"],
      notes: nil,
      data_source_url: inmate["InmateId"] && "https://search.dupagesheriff.org/inmate/details/#{inmate["InmateId"]}"
    }
    mugshot[:md5_hash] = calc_md5_hash(mugshot)
    mugshot
  end

  def parse_arrestee_id(inmate, arrestee_id)
    inmate_id = {
      arrestee_id: arrestee_id,
      number: inmate["InmateNumber"],
      type: "Inmate #",
      data_source_url: inmate["InmateId"] && "https://search.dupagesheriff.org/inmate/details/#{inmate["InmateId"]}"
    }
    inmate_id[:md5_hash] = calc_md5_hash(inmate_id)
    inmate_id
  end

  def parse_arrest(inmate, arrestee_id)
    arrest = {
      arrestee_id: arrestee_id,
      status: inmate["Status"].presence,
      booking_date: inmate["DateOfBookingFormatted"] && Date.strptime(inmate["DateOfBookingFormatted"], '%m/%d/%Y'),
      data_source_url: inmate["InmateId"] && "https://search.dupagesheriff.org/inmate/details/#{inmate["InmateId"]}"
    }
    arrest[:booking_number] = "#{arrest[:booking_date]}-#{inmate["InmateNumber"]}"
    arrest[:actual_booking_number] = 0
    arrest[:md5_hash] = calc_md5_hash(arrest)
    arrest
  end

  def parse_charges(inmate, arrest_id)
    charges = inmate["Charges"]
    inmate_charges = charges.map do |c|
      charge = {
        arrest_id: arrest_id,
        number: c["CountNumber"].presence,
        description: c["StatuteDescription"],
        docket_number: c["CaseNumber"],
        data_source_url: inmate["InmateId"] && "https://search.dupagesheriff.org/inmate/details/#{inmate["InmateId"]}"
      }
      charge[:md5_hash] = calc_md5_hash(charge)
      charge[:court_room] = c["CourtRoom"].presence
      charge
    end
    inmate_charges
  end

  def parse_court_hearing(charge, court_room, charge_db_id)
    court_hearing = {
      charge_id: charge_db_id,
      court_room: court_room,
      case_number: charge[:docket_number],
      data_source_url: charge[:data_source_url]
    }
    court_hearing[:md5_hash] = calc_md5_hash(court_hearing)
    court_hearing
  end

  def parse_bonds(inmate, arrest_id)
    bonds = inmate["Bonds"]
    bond_sum = 0
    inmate_bonds = bonds.map do |b|
      bond = {
        arrest_id: arrest_id,
        bond_category: "Surety Bond",
        bond_number: b["CaseNumber"],
        bond_amount: b["BondAmount"].presence,
        data_source_url: inmate["InmateId"] && "https://search.dupagesheriff.org/inmate/details/#{inmate["InmateId"]}"
      }
      bond[:md5_hash] = calc_md5_hash(bond)
      bond_sum += bond[:bond_amount].to_i
      bond
    end

    unless bonds.empty?
      total_bond = {
        arrest_id: arrest_id,
        bond_category: "Total Bond",
        bond_amount: bond_sum.to_s,
        data_source_url: inmate["InmateId"] && "https://search.dupagesheriff.org/inmate/details/#{inmate["InmateId"]}"
      }
      total_bond[:md5_hash] = calc_md5_hash(total_bond)
      inmate_bonds.push(total_bond)
    end

    inmate_bonds
  end

  def calc_md5_hash(hash)
    values_string = ''
    hash.values.each do |val|
      values_string += val.to_s
    end
    Digest::MD5.hexdigest values_string
  end

  # def parse_arrestee_address(inmate, arrestee_id)
  #   inmate_address = {
  #     arrestee_id: arrestee_id,
  #     data_source_url: inmate["InmateId"] && "https://search.dupagesheriff.org/inmate/details/#{inmate["InmateId"]}"
  #   }
  #   inmate_address[:md5_hash] = calc_md5_hash(inmate_address)
  #   inmate_address
  # end

  # def parse_arrestee_alias(inmate, arrestee_id)
  #   inmate_alias = {
  #     arrestee_id: arrestee_id,
  #     full_name: "#{inmate["LastName"]}, #{inmate["FirstName"]}",
  #     first_name: inmate["FirstName"].presence,
  #     last_name: inmate["LastName"].presence,
  #     data_source_url: inmate["InmateId"] && "https://search.dupagesheriff.org/inmate/details/#{inmate["InmateId"]}"
  #   }
  #   inmate_alias[:md5_hash] = calc_md5_hash(inmate_alias)
  #   inmate_alias
  # end

  # def parse_holding_facility(inmate, arrest_id)
  #   holding_facility = {
  #     arrest_id: arrest_id,
  #     data_source_url: inmate["InmateId"] && "https://search.dupagesheriff.org/inmate/details/#{inmate["InmateId"]}"
  #   }
  #   holding_facility[:md5_hash] = calc_md5_hash(holding_facility)
  #   holding_facility
  # end
end
