class TxDocumentList
  def initialize(court_map, case_detail_page, default_url, scrape_dev_name, run_id, link, case_id)
    @document_list_page = Nokogiri::HTML(case_detail_page)

    @court = @document_list_page.css("//h1[id='pageName']").text.strip
    @court_id = get_court_id(court_map, @court)
    @case_id = case_id
    @court_map = court_map

    @scrape_dev_name = scrape_dev_name
    @default_url = default_url
    @data_source_url = link
    @run_id = run_id

    @md5_cash_maker = {
      case_activities: MD5Hash.new(columns: %i[court_id case_id activity_date activity_type activity_desc file data_source_url])
    }
  end

  def tx_case_activities_nil?
    activities = @document_list_page.xpath("//table[contains(@id, '_grdEvents_')]/tbody").xpath('./tr')
    activities.size == 0 ? true : false
  end

  def tx_case_activities
    name, type, desc, file = ''

    case_activities = []

    tx_saac_case_activity_table = @document_list_page.xpath("//table[contains(@id, '_grdEvents_')]/tbody")
    rows = tx_saac_case_activity_table.xpath('./tr')

    rows.each do |row|
      next if row.xpath('./td')[0].xpath('./div').text.strip == 'Your search found no results. Try broadening your search criteria.'

      date = Date.strptime(row.xpath('./td')[0].text.strip, '%m/%d/%Y') unless row.xpath('./td')[0].nil?
      type = row.xpath('./td')[1].text.strip

      row_td = row.xpath("./td/div/table")
      file = row_td.nil? ? nil : row_td.xpath('./tr').xpath('./td')[0]
      desc = (row_td.nil? || row_td.xpath('./tr').xpath('./td')[1].nil?) ? nil : row_td.xpath('./tr').xpath('./td')[1].text.strip

      unless file.nil?
        file = file.css('a').size > 0 ? @default_url + file.css('a')[0]['href'] : nil
      end

      case_activity_hash = {
        court_id: @court_id,
        case_id:  @case_id,

        activity_date:        date,
        activity_type:        type,
        activity_desc:        desc,
        file:                 file,

        data_source_url:  @data_source_url + "?cn=#{@case_id}&#{get_court_param(@court_map, @court)}",
        scrape_frequency: 'daily',
        created_by:       @scrape_dev_name,
        run_id:           @run_id
      }

      hash = case_activity_hash.as_json

      arrest_md5_hash = @md5_cash_maker[:case_activities].generate(hash)
      case_activity_hash[:md5_hash] = arrest_md5_hash

      case_activity_exist = TxSaacCaseActivities.where(md5_hash: case_activity_hash[:md5_hash])
      case_activity_exist_first = case_activity_exist.first

      if case_activity_exist_first.nil?
        case_activities << case_activity_hash
      else
        if case_activity_exist.size == 1
          TxSaacCaseActivities.update(case_activity_exist_first[:id], run_id: @run_id, touched_run_id: @run_id)
        elsif case_activity_exist.size > 1
          case_activity_exist.each_with_index do |row, index|
            TxSaacCaseActivities.update(row[:id], run_id: @run_id, touched_run_id: @run_id)
          end
        end
      end
    end

    case_activities.size > 0 ? case_activities : nil
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
