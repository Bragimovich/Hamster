# https://search.txcourts.gov/Case.aspx?cn=01-22-00243-CV&coa=coa01

class TxCaseDetail < Hamster::Scraper
  def initialize(court_map, case_detail_page, data_source_url, scrape_dev_name, run_id)
    @case_detail_page = Nokogiri::HTML(case_detail_page)

    @court = @case_detail_page.css("//h1[id='pageName']").text.strip
    @court_id = get_court_id(court_map, @court)
    @case_id = ''
    @court_map = court_map

    @scrape_dev_name = scrape_dev_name
    @data_source_url = data_source_url
    @run_id = run_id

    @md5_cash_maker = {
      case_info: MD5Hash.new(columns: %i[court_id case_id case_name case_filed_date case_type case_description disposition_or_status status_as_of_date judge_name lower_court_id lower_case_id data_source_url]),
      case_party: MD5Hash.new(columns: %i[court_id case_id party_name party_type is_lawyer party_law_firm party_address party_city party_state party_zip party_description data_source_url]),
      case_additional_info: MD5Hash.new(columns: %i[court_id case_id lower_court_name lower_case_id lower_judge_name lower_link disposition data_source_url]),
    }

  end

  def tx_case_info
    case_name, case_filed_date, case_type, case_description, disposition_or_status,
      status_as_of_date, judge_name, lower_court_id, lower_case_id = ''

    # info
    info = @case_detail_page.css("//div[id='panelTextSelection']/div[class='panel-content']/div[class='row-fluid']")

    info.each do |el|
      label = el.css("/div")[0].text.strip
      content = el.css("/div")[1].text.strip unless el.css("/div")[1].text.strip.blank?

      case label
      when 'Case:'
        @case_id = content
      when 'Date Filed:'
        case_filed_date = Date.strptime(content, '%m/%d/%Y') unless content.blank?
      when 'Case Type:'
        case_type = content
      when 'Style:'
        case_name = content
      when 'v.:'
        case_name += ('v. ' + content) unless content.blank?
      else
        nil
      end
    end

    # calendar
    calendar = @case_detail_page.xpath("//table[contains(@id, '_grdCalendar_')]/tbody").xpath('./tr')

    calendar = calendar.last if calendar.size > 1
    status_as_of_date = calendar.xpath('./td')[2].nil? ? nil : calendar.xpath('./td')[2].text.strip

    # trial_court_panel
    trial_court_panel = @case_detail_page.css("//div[id='panelTrialCourtInfo']/div[class='panel-content']/div[class='row-fluid']")
    trial_court_panel.each do |el|
      label = el.css("/div")[0].text.strip
      content = el.css("/div")[1].text.strip unless el.css("/div")[1].text.strip.blank?

      case label
      when 'Court Case'
        lower_case_id = content.gsub(/[[:space:]]/, ' ').strip unless content.nil?
      when 'Court Judge'
        judge_name = content.gsub(/[[:space:]]/, ' ').strip unless content.nil?
      else
        nil
      end
    end

    case_info_hash = {
      court_id: @court_id,
      case_id: @case_id,

      case_name: case_name.gsub(/[[:space:][:space:]]/, ' ').strip,
      case_filed_date: case_filed_date,
      case_type: case_type,
      case_description: case_description,
      disposition_or_status: disposition_or_status,
      status_as_of_date: status_as_of_date,
      judge_name: judge_name,
      lower_court_id: lower_court_id,
      lower_case_id: lower_case_id,

      data_source_url: @data_source_url + "?cn=#{@case_id}&#{get_court_param(@court_map, @court)}",
      scrape_frequency: 'weekly',
      created_by: @scrape_dev_name,
      run_id: @run_id
    }

    hash = case_info_hash.as_json

    arrest_md5_hash = @md5_cash_maker[:case_info].generate(hash)
    case_info_hash[:md5_hash] = arrest_md5_hash

    case_info_exist = TxSaacCaseInfo.where(md5_hash: case_info_hash[:md5_hash])
    case_info_exist_first = case_info_exist.first

    if case_info_exist_first.nil?
      case_info_hash
    else
      if case_info_exist.size == 1
        TxSaacCaseInfo.update(case_info_exist_first[:id], run_id: @run_id, touched_run_id: @run_id)
      elsif case_info_exist.size > 1
        case_info_exist.each_with_index do |row, index|
          TxSaacCaseInfo.update(row[:id], run_id: @run_id, touched_run_id: @run_id)
        end
      end
    end

    case_info_hash.nil? ? nil : case_info_hash
  end

  def tx_case_parties_nil?
    tx_saac_case_party_table = @case_detail_page.xpath("//table[contains(@id, '_grdParty_')]/tbody").xpath('./tr')
    tx_saac_case_party_table.size == 0 ? true : false
  end

  def tx_case_parties
    name, type, law_firm, address, city,
      state, zip, desc = ''

    case_parties = []

    tx_saac_case_party_table = @case_detail_page.xpath("//table[contains(@id, '_grdParty_')]/tbody")
    rows = tx_saac_case_party_table.xpath('./tr')

    rows.each do |row|
      is_lawyer = 0
      name = row.xpath('./td')[0].text.strip unless row.xpath('./td')[0].nil?
      type = row.xpath('./td')[1].text.strip unless row.xpath('./td')[1].nil?

      result = work_with_party(name, type, is_lawyer, law_firm, address, city, state, zip, desc)
      case_parties << result unless result.nil?

      unless row.xpath('./td')[2].text.strip.blank?
        if row.xpath('./td')[2].to_s.include?('<br>')
          row.xpath('./td')[2].to_s.split('<br>').each do |lawyer|
            lawyer = lawyer.gsub('<td>', '').gsub('</td>', '').strip
            unless lawyer.blank?
              is_lawyer = 1
              name = lawyer
              party_type = row.xpath('./td')[1].text.strip
              type = party_type.include?('Lawyer') ? party_type : party_type + ' Lawyer'

              result = work_with_party(name, type, is_lawyer, law_firm, address, city, state, zip, desc)
              case_parties << result unless result.nil?
            end
          end
        else
          is_lawyer = 1
          name = row.xpath('./td')[2].text.strip
          party_type = row.xpath('./td')[1].text.strip
          type = party_type.include?('Lawyer') ? party_type : party_type + ' Lawyer'

          result = work_with_party(name, type, is_lawyer, law_firm, address, city, state, zip, desc)
          case_parties << result unless result.nil?
        end
      end
    end
    case_parties.size > 0 ? case_parties : nil
  end

  def work_with_party(name, type, is_lawyer, law_firm, address, city, state, zip, desc)
    parties = []
    case_party_hash = {
      court_id: @court_id,
      case_id: @case_id,

      party_name: name.gsub(/[[:space:]]/, ' ').strip,
      party_type: type,

      is_lawyer: is_lawyer,
      party_law_firm: law_firm,
      party_address: address,
      party_city: city,
      party_state: state,
      party_zip: zip,
      party_description: desc,

      data_source_url: @data_source_url + "?cn=#{@case_id}&#{get_court_param(@court_map, @court)}",
      scrape_frequency: 'daily',
      created_by: @scrape_dev_name,
      run_id: @run_id
    }

    hash = case_party_hash.as_json

    arrest_md5_hash = @md5_cash_maker[:case_party].generate(hash)
    case_party_hash[:md5_hash] = arrest_md5_hash

    case_party_exist = TxSaacCaseParty.where(md5_hash: case_party_hash[:md5_hash])
    case_party_exist_first = case_party_exist.first

    if case_party_exist_first.nil?
      parties << case_party_hash
    else
      if case_party_exist.size == 1
        TxSaacCaseParty.update(case_party_exist_first[:id], run_id: @run_id, touched_run_id: @run_id)
      elsif case_party_exist.size > 1
        case_party_exist.each_with_index do |row, index|
          TxSaacCaseParty.update(row[:id], run_id: @run_id, touched_run_id: @run_id)
        end
      end
    end
    parties.size > 0 ? case_party_hash : nil
  end

  def tx_case_additional_info_nil?
    additional_info_table = @case_detail_page.css("//div[id='panelTrialCourtInfo']/div[class='panel-content']/div[class='row-fluid']")
    additional_info_table.size > 0 ? false : true
  end

  def tx_case_additional_info
    lower_court_name, lower_case_id, lower_judge_name, lower_link, disposition = ''

    # trial_court_panel
    additional_info_table = @case_detail_page.css("//div[id='panelTrialCourtInfo']/div[class='panel-content']/div[class='row-fluid']")
    additional_info_table.each do |el|
      label = el.css("/div")[0].text.strip
      content = el.css("/div")[1].text.strip unless el.css("/div")[1].text.strip.blank?

      case label
      when 'Court Case'
        lower_case_id = content.gsub(/[[:space:][:space:]]/, ' ').strip unless content.nil?
      when 'Court Judge'
        lower_judge_name = content.gsub(/[[:space:][:space:]]/, ' ').strip unless content.nil?
      when 'Court'
        lower_court_name = content.gsub(/[[:space:][:space:]]/, ' ').strip unless content.nil?
      else
        nil
      end
    end

    case_additional_info_hash = {
      court_id: @court_id,
      case_id: @case_id,

      lower_court_name: lower_court_name,
      lower_case_id: lower_case_id,
      lower_judge_name: lower_judge_name,
      lower_link: lower_link,
      disposition: disposition,

      data_source_url: @data_source_url + "?cn=#{@case_id}&#{get_court_param(@court_map, @court)}",
      scrape_frequency: 'weekly',
      created_by: @scrape_dev_name,
      run_id: @run_id
    }

    hash = case_additional_info_hash.as_json

    arrest_md5_hash = @md5_cash_maker[:case_additional_info].generate(hash)
    case_additional_info_hash[:md5_hash] = arrest_md5_hash

    case_additional_info_exist = TxSaacCaseAdditionalInfo.where(md5_hash: case_additional_info_hash[:md5_hash])
    case_add_info_exist_first = case_additional_info_exist.first

    if case_add_info_exist_first.nil?
      case_additional_info_hash
    else
      if case_additional_info_exist.size == 1
        TxSaacCaseAdditionalInfo.update(case_add_info_exist_first[:id], run_id: @run_id, touched_run_id: @run_id)
      elsif case_additional_info_exist.size > 1
        case_additional_info_exist.each_with_index do |row, index|
          TxSaacCaseAdditionalInfo.update(row[:id], run_id: @run_id, touched_run_id: @run_id)
        end
      end
    end

    case_additional_info_hash.nil? ? nil : case_additional_info_hash
  end

  def get_court_id(court_map, court)
    court_id = 0

    court_map.each do |map|
      if map[1][0] == court
        court_id = map[1][2]
        break
      end
    end

    court_id
  end

  def get_court_param(court_map, court)
    court_id = 0

    court_map.each do |map|
      if map[1][0] == court
        court_id = map[1][3]
        break
      end
    end

    court_id
  end

end

