CANDIDATE_PREFIX = "span#ctl00_ContentPlaceHolder1_Name_Reports1_TabContainer1_TabPanel2_lbl"
COMMITTEE_PREFIX = "span#ctl00_ContentPlaceHolder1_Name_Reports1_TabContainer1_TabPanel3_"

class Parser < Hamster::Harvester
  def initialize
    super
  end

  def parse_candidate(source)
    data_source_url = source.env.url.to_s
    @doc = Nokogiri::HTML(source&.body)
    {
      filer_id:                 get('FilerID'),
      candidate_full_name:      get('Name'),
      candidate_address1:       get('Address'),
      candidate_address2:       get('Address2'),
      candidate_csz:            get('CSZ'),
      candidate_phone1:         get('Telephone'),
      candidate_phone2:         get('Secondary'),
      candidate_party:          get('PartyAffiliation'),
      candidate_office_sought:  get('OfficeSought'),
      committee_name:           get('ComName'),
      committee_address1:       get('ComAddress'),
      committee_address2:       get('ComAddress1'),
      committee_csz:            get('ComCSZ'),
      committee_phone1:         get('ComPhone1'),
      committee_phone2:         get('ComPhone2'),
      data_source_url:          data_source_url
    }
  end

  def parse_committee(source)
    data_source_url = source.env.url.to_s
    @doc = Nokogiri::HTML(source&.body)
    {
      filer_id:                 get('Label17'),
      committee_name:           get('Label18'),
      committee_address1:       get('Label19'),
      committee_address2:       get('Label20'),
      committee_csz:            get('Label21'),
      committee_phone1:         get('Label22'),
      committee_phone2:         get('Label23'),
      committee_affiliation:    get('lblAffiliation'),
      committee_type:           get('lblComType'),
      committee_recall_office:  get('lblRecallOffice'),
      committee_recall_officer: get('lblRecallOfficer'),
      data_source_url:          data_source_url
    }
  end

  def get(param)
    prefix = param.downcase.start_with?('l') ? COMMITTEE_PREFIX : CANDIDATE_PREFIX
    @doc.at_css("#{prefix}#{param}").text
  end
end
