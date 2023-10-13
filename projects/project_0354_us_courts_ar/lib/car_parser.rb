# frozen_string_literal: true

class Parser < Hamster::Scraper
  def initialize(court_id)
    super
    @court_id = court_id
  end

  def index_page(html)
    doc = Nokogiri::HTML(html)
    table = doc.css('table')
    cases = []
    return cases if table.empty?

    table.css('tr')[1..].each do |tr|
      td = tr.css('td')
      link = td[1].css('a')[0]
      next if link.nil?

      cases << {case_id: link.content}
    end
    cases
  end

  def case_page(html, case_id)
    @data_source_url = "https://caseinfo.arcourts.gov/cconnect/PROD/public/ck_public_qry_doct.cp_dktrpt_docket_report?backto=C&case_id=#{case_id}&citation_no=&begin_date=&end_date="
    { info:  get_info(html, case_id),
      party: get_party(html, case_id),
      activities: get_activities(html, case_id)}
  end

  INFO_HASH = {"Case ID:" => :case_name,"Filing Date:"=>:case_filed_date, "Type:"=> :case_type, "Status:" => :status_as_of_date}

  def get_info(html, case_id)
    info_html = html.split('<a name="description">')[-1].split('<a name="events">')[0]
    info_doc = Nokogiri::HTML(info_html)
    info = {court_id: @court_id,
            case_id: case_id,}
    info_doc.css('tr').each do |tr|
      td = tr.css('td')
      next if td.length<3
      info[INFO_HASH[td[1].content.strip]] = td[2].content.strip[1..]
    end
    info[:case_filed_date] = Date.parse(info[:case_filed_date])
    info[:case_name] = info[:case_name].split(case_id)[1].split('-')[1..].join('-').strip if !info[:case_name].nil?
    info[:data_source_url] = @data_source_url

    info.delete(nil)
    info
  end

  def get_party(html, case_id)
    party_html = html.split('<a name="parties">')[-1].split('<a name="violations">')[0]
    party_doc = Nokogiri::HTML(party_html)
    tr = party_doc.css('tr')[1..]
    parties = []
    parties_number = tr.length/3
    (0..parties_number-1).each do |i|
      party_type = tr[i*3].css('td')[3]
      party_name = tr[i*3].css('td')[5]
      parties << { court_id: @court_id,
                   case_id: case_id,
                   party_type: !party_type.nil? ? party_type.content.strip : nil,
                   party_name: !party_name.nil? ? party_name.content.strip : nil,
                   data_source_url: @data_source_url}
    end
    parties
  end

  def get_activities(html, case_id)
    activities_html = html.split('<a name="dockets">')[-1]
    activity_doc = Nokogiri::HTML(activities_html)
    tr = activity_doc.css('tr')[1..]
    p case_id
    activities = []
    activities_number = tr.nil? ? 0 : tr.size/4
    add_row = 0
    (0..activities_number-1).each do |i|

      row = i*4 + add_row
      activity_date = tr[row].css('td')[0] if !tr[row].nil?
      if activity_date.nil? or !activity_date.content.strip.match(/\d{2}\/\d{2}\/\d{6}/)
        add_row += 1
        row += 1
        break if tr[row].nil?
        activity_date = tr[row].css('td')[0]
      end
      activity_type = tr[row].css('td')[1]
      activity_desc = tr[row+1].css('td')[1]
      activity_file = tr[row+2].css('td')[1].css('a')[0] if !tr[row+2].css('td')[1].nil?
      activity_date = ( Date.strptime(activity_date.content.strip[0..9], '%m/%d/%Y') rescue nil )

      additional_activity_rows = 0
      while !tr[row+3+additional_activity_rows].css('td')[1].nil?
        activities << { court_id: @court_id,
                        case_id: case_id,
                        activity_date: activity_date,
                        activity_type: tr[row+3+additional_activity_rows].css('td')[1].content,
                        activity_desc: !activity_desc.nil? ? activity_desc.content.strip : nil,
                        file: tr[row+3+additional_activity_rows].css('td')[1].css('a')[0]['href'], #activity_file
                        data_source_url: @data_source_url}
        additional_activity_rows += 1
        add_row += 1
      end
      activities << { court_id: @court_id,
                      case_id: case_id,
                      activity_date: activity_date,
                      activity_type: !activity_type.nil? ? activity_type.content.strip : nil,
                      activity_desc: !activity_desc.nil? ? activity_desc.content.strip : nil,
                      file: !activity_file.nil? ? activity_file['href'] : nil, #activity_file
                      data_source_url: @data_source_url}
    end
    activities
  end
end
