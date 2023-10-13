# frozen_string_literal: true

class HashConvertor
  def activity_to_md5(court_id, case_id, activity_date, activity_decs, activity_pdf)
    not_computed = court_id + case_id + activity_date + activity_decs + activity_pdf
    Digest::MD5.hexdigest not_computed
  end

  def case_info_to_md5(court_id, case_title, case_id, case_date,
                       case_type, judge, case_description)
    not_computed = court_id + case_title + case_id + case_date +
      case_type + judge + case_description
    Digest::MD5.hexdigest not_computed
  end

  def party_to_md5(court_id, case_id, party_name, party_type,
                   party_address, party_city, party_state, party_zip,
                   law_firm, is_lawyer)
    not_computed = court_id + case_id + party_name + party_type + party_address +
      party_city + party_state + party_zip + law_firm + is_lawyer
    Digest::MD5.hexdigest not_computed
  end

  def court_to_md5(court_name, court_state, court_type, court_sub_type)
    not_computed = court_name + court_state + court_type + court_sub_type
    Digest::MD5.hexdigest not_computed
  end
end
