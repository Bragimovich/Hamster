# frozen_string_literal: true
class CTCaseDetail < Hamster::Scraper
  def initialize(case_detail_page, data_source_url, filed_date, scrape_dev_name, court_id, run_id)
    @detail_page = Nokogiri::HTML(case_detail_page)

    @court_id = court_id
    if court_id == 307
      if !@detail_page.css('span:contains("PETITION")').blank? || !@detail_page.css('span:contains("petition")').blank?
        @case_id = 'Pet ' + @detail_page.css("//span[id='lblAppealNo']").text.to_s.strip
      elsif !@detail_page.css('span:contains("MOTION")') || !@detail_page.css('span:contains("motion")')
        @case_id = 'Mot ' + @detail_page.css("//span[id='lblAppealNo']").text.to_s.strip
      else
        @case_id = @detail_page.css("//span[id='lblAppealNo']").text.to_s.strip
      end
    else
      @case_id = @detail_page.css("//span[id='lblAppealNo']").text.to_s.strip
    end

    @scrape_dev_name = scrape_dev_name
    @data_source_url = data_source_url
    @run_id = run_id
    @ct_saac_case_party = CtSaacCaseParty

    @md5_cash_maker = {
      case_info: MD5Hash.new(columns: %i[court_id case_id case_name case_filed_date case_type case_description disposition_or_status status_as_of_date judge_name data_source_url]),
      case_party: MD5Hash.new(columns: %i[court_id case_id is_lawyer party_name party_type party_law_firm party_address party_city party_state party_zip party_description data_source_url]),
      case_additional_info: MD5Hash.new(columns: %i[court_id case_id lower_court_name lower_case_id lower_judge_name lower_judgement_date lower_link disposition data_source_url])
    }
  end

  def connect_to_db(database = :us_court_cases)
    Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
  end

  def ct_case_info
    return nil if @case_id.blank?

    client = connect_to_db
    begin
      case_info = []
      case_info_h = {
        case_id: @case_id,
        court_id: @court_id,

        case_name: @detail_page.css("//span[id='lblCaseName']").text.strip,
        case_filed_date: @detail_page.css("//span[id='lblDateFiled']").text.strip,
        case_type: @detail_page.css("//span[id='lblCaseType']").text.strip,
        case_description: @detail_page.css("//span[id='lblCaseDescription']").text.strip,
        disposition_or_status: @detail_page.css("//span[id='lblDispMethod']").text.strip,
        status_as_of_date: @detail_page.css("//span[id='lblCaseStatus']").text.strip,
        judge_name: @detail_page.css("//span[id='lblJudgeName']").text.strip,

        data_source_url: @data_source_url,
        created_by: @scrape_dev_name,
        run_id: @run_id
      }
      unless case_info_h[:case_filed_date].blank?
        case_info_h[:case_filed_date] = Date.strptime(case_info_h[:case_filed_date], "%m/%d/%Y")
      end

      hash = case_info_h.as_json
      md5 = @md5_cash_maker[:case_info].generate(hash)

      case_info_h[:md5_hash] = md5

      query = "SELECT * FROM us_court_cases.ct_saac_case_info
             WHERE md5_hash = '#{md5}' and deleted = 0;"
      case_info_exist = client.query(query).to_a

      case_info_exist_first = case_info_exist.first

      if case_info_exist_first.nil?
        case_info << case_info_h
      elsif case_info_exist.size == 1
        query = "UPDATE us_court_cases.ct_saac_case_info
               SET run_id = '#{@run_id}', touched_run_id = '#{@run_id}'
               WHERE id = #{case_info_exist_first[:id]}"
        client.query(query)
      elsif case_info_exist.size > 1
        case_info_exist.each_with_index do |row, index|
          query = "UPDATE us_court_cases.ct_saac_case_info
               SET run_id = '#{@run_id}', touched_run_id = '#{@run_id}'
               WHERE id = #{row[:id]}"
          client.query(query)
        end
      end

      case_info
    ensure
      client.close
    end
  end

  def ct_case_parties_nil?
    ct_saac_case_party_table = @detail_page.css('//table[@id="gvPartyCounsel"]')
    rows = ct_saac_case_party_table.xpath('./tr')

    rows.size.zero?
  end

  def ct_case_parties
    case_parties = []

    ct_saac_case_party_table = @detail_page.css('//table[@id="gvPartyCounsel"]')
    rows = ct_saac_case_party_table.xpath('./tr')
    rows.shift.css('th')

    loop do
      break if rows.size.zero?
      row = rows.pop
      break if row.nil?

      if row.xpath("./td/span[contains(@id, '_lblAppealPartyClass')]").text.blank? ||
        row.xpath("./td/span[contains(@id, '_lblAppealPartyClass')]").text == 'Unknown'
        add_type = row.xpath('./td')[1].text unless row.xpath('./td')[1].nil? && row.xpath('./td')[1].text.blank?
        party_type = 'Unknown' + ' ' + add_type
      else
        _party_type = row.xpath("./td/span[contains(@id, '_lblAppealPartyClass')]")
        _party_type.css('br').each { |br| br.replace('; ') }
        party_type = _party_type.text
      end

      is_lawyer = 0
      party_name = row.xpath("./td/span[contains(@id, '_lblPartyName')]").text.strip

      arr = work_with_party(party_name, party_type, is_lawyer)
      case_parties.concat(arr) unless arr.empty?

      # Additional Parties
      next unless row.xpath(".//table[contains(@id, '_dlCounsel')]").xpath('./tr').size.positive?
      table_rows = row.xpath(".//table[contains(@id, '_dlCounsel')]").xpath('./tr')

      table_rows.each do |add_row|

        party_name = add_row.search("td.jurisnamecell")[0].text
        next if party_name.blank?

        _party_type = add_row.search('td.juriscell')[0].text.gsub(':', '')

        if party_type.blank? && _party_type.include?('Self Rep')
          _type = _party_type
        elsif !party_type.blank? && _party_type.include?('Self Rep')
          _type = party_type + '; ' + _party_type
        else
          _type = party_type
        end

        is_lawyer = 1

        arr_add = work_with_party(party_name, _type, is_lawyer)

        case_parties.concat(arr_add) unless arr_add.empty?
      end
    end

    case_parties.uniq { |e| e[:md5_hash] }
  end

  def work_with_party(party_name, party_type, is_lawyer)
    client = connect_to_db

    begin
      case_parties = []
      case_party_hash = {
        case_id: @case_id,
        court_id: @court_id,

        party_type: party_type,
        is_lawyer: is_lawyer,
        party_name: party_name,
        party_law_firm: '',

        data_source_url: @data_source_url,
        created_by: @scrape_dev_name,
        run_id: @run_id
      }

      hash = case_party_hash.as_json
      md5 = @md5_cash_maker[:case_party].generate(hash)
      case_party_hash[:md5_hash] = md5

      query = "SELECT * FROM us_court_cases.ct_saac_case_party
             WHERE md5_hash = '#{md5}' and deleted = 0;"
      case_party_exist = client.query(query).to_a

      case_party_exist_first = case_party_exist.first

      if case_party_exist_first.nil? && !case_party_hash[:party_name].blank?
        case_parties << case_party_hash
      elsif case_party_exist.size == 1
        query = "UPDATE us_court_cases.ct_saac_case_party
               SET run_id = '#{@run_id}', touched_run_id = '#{@run_id}'
               WHERE id = #{case_party_exist_first[:id]}"
        client.query(query)
      elsif case_party_exist.size > 1
        case_party_exist.each_with_index do |row, index|
          query = "UPDATE us_court_cases.ct_saac_case_party
               SET run_id = '#{@run_id}', touched_run_id = '#{@run_id}'
               WHERE id = #{row[:id]}"
          client.query(query)
        end
      end

      case_parties
    ensure
      client.close
    end
  end

  def ct_case_additional_info_nil?
    lower_case_ids = @detail_page.xpath('//a[starts-with(@id, "dlTCDockets_ct")]')
    lower_case_ids.size == 0
  end

  def ct_case_additional_info
    client = connect_to_db
    begin
      additional_info_table = @detail_page.css("//table[id='tblTrialCourtInfoSec']")
      case_additional_info = []

      lower_case_ids = @detail_page.xpath('//a[starts-with(@id, "dlTCDockets_ct")]')

      return nil if lower_case_ids.size == 0

      lower_case_ids.each_with_index do |lower_case_id, index|
        lower_case_id = lower_case_id.text.strip
        lower_link = additional_info_table.css('a')[index]['href']

        add_info_hash = {
          court_id: @court_id,
          case_id: @case_id,

          lower_court_name: @detail_page.css("//span[id='lblCourt']").text.strip,
          lower_case_id: lower_case_id,
          lower_judge_name: @detail_page.css("//span[id='lblTrialJudge']").text.strip,
          lower_judgement_date: @detail_page.css("//span[id='lblJudgementdate']").text.strip,
          lower_link: lower_link,

          data_source_url: @data_source_url,
          created_by: @scrape_dev_name,
          run_id: @run_id
        }

        unless add_info_hash[:lower_judgement_date].blank?
          add_info_hash[:lower_judgement_date] = Date.strptime(add_info_hash[:lower_judgement_date], "%m/%d/%Y")
        end

        hash = add_info_hash.as_json
        md5 = @md5_cash_maker[:case_additional_info].generate(hash)
        add_info_hash[:md5_hash] = md5

        query = "SELECT * FROM us_court_cases.ct_saac_case_additional_info
             WHERE md5_hash = '#{md5}' and deleted = 0;"
        case_additional_info_exist = client.query(query).to_a

        case_add_info_exist_first = case_additional_info_exist.first

        if case_add_info_exist_first.nil?
          case_additional_info << add_info_hash
        elsif case_additional_info_exist.size == 1
          query = "UPDATE us_court_cases.ct_saac_case_additional_info
               SET run_id = '#{@run_id}', touched_run_id = '#{@run_id}'
               WHERE id = #{case_add_info_exist_first[:id]}"
          client.query(query)
        elsif case_additional_info_exist.size > 1
          case_additional_info_exist.each_with_index do |row, index|
            query = "UPDATE us_court_cases.ct_saac_case_additional_info
               SET run_id = '#{@run_id}', touched_run_id = '#{@run_id}'
               WHERE id = #{row[:id]}"
            client.query(query)
          end
        end
      end
      case_additional_info.uniq { |e| e[:md5_hash] }
    ensure
      client.close
    end
  end
end

