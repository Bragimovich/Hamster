class CaseDetail < Hamster::Scraper
    def initialize(case_detail_page, filed_date, scrape_dev_name, data_source_url, docket_id=nil, court_id=nil)
      @case_detail_page = Nokogiri::HTML(case_detail_page)
      @court_name = @case_detail_page.xpath("//span[@class='PageHeadingDesc']").text.strip

      @court_id = court_id
      @court_id = COURTS.values.select { |details| details[:court_name] == @court_name }.first[:id] if court_id.nil?

      @case_id = @case_detail_page.xpath("//a[@class='skipTo']").text
      @case_id = docket_id if !@case_id.match('ot Assigned').nil?
      @filed_date = filed_date
      @scrape_dev_name = scrape_dev_name
      @data_source_url = data_source_url
    end

    def case_parties
      petitioners = @case_detail_page.xpath("//table[@summary='Petitioners in this case']/tbody/tr/td[1]").map(&:text).map(&:strip)
      respondents = @case_detail_page.xpath("//table[@summary='Respondents in this case']/tbody/tr/td[1]").map(&:text).map(&:strip)

      case_parties = []
      petitioners.each do |petitioner|
        case_party_hash = {
          case_number: @case_id,
          party_name: petitioner,
          party_type: 'plantiff',
          data_source_url: @data_source_url,
          scrape_frequency: 'daily',
          expected_scrape_frequency: 'daily',
          last_scrape_date: Date.today,
          next_scrape_date: Date.today + 1,
          pl_gather_task_id: '177729443',
          court_id: @court_id,
          scrape_dev_name: @scrape_dev_name
        }

        md5  = PacerMD5.new(data: case_party_hash, table: 'party_root')
        case_party_hash[:md5_hash] = md5.hash

        case_parties << case_party_hash

      end

      respondents.each do |respondent|
        case_party_hash = {
          case_number: @case_id,
          party_name: respondent,
          party_type: 'defendant',
          data_source_url: @data_source_url,
          scrape_frequency: 'daily',
          expected_scrape_frequency: 'daily',
          last_scrape_date: Date.today,
          next_scrape_date: Date.today + 1,
          pl_gather_task_id: '177729443',
          court_id: @court_id,
          scrape_dev_name: @scrape_dev_name
        }

        md5  = PacerMD5.new(data: case_party_hash, table: 'party_root')
        case_party_hash[:md5_hash] = md5.hash

        case_parties << case_party_hash

      end

      case_parties
    end

    def case_info
      case_info_hash = {
        court_name: @court_name,
        court_state: 'New York',
        court_type: 'Supreme Court',
        case_name: @case_detail_page.xpath("//span[@class='captionText']").text.strip,
        case_id: @case_id,
        case_filed_date: @filed_date,
        case_type: @case_detail_page.xpath("//span[contains(., 'Case Type')]/strong").text.strip,
        #disposition_or_status: @case_detail_page.xpath("//span[contains(., 'Case Status')]/strong").text.strip,
        status_as_of_date: @case_detail_page.xpath("//span[contains(., 'Case Status')]/strong").text.strip,
        judge_name: @case_detail_page.xpath("//span[contains(., 'Assigned Judge')]/strong").text.strip,
        data_source_url: @data_source_url,
        scrape_frequency: 'daily',
        expected_scrape_frequency: 'daily',
        last_scrape_date: Date.today,
        next_scrape_date: Date.today + 1,
        pl_gather_task_id: '177729443',
        court_id: @court_id,
        scrape_dev_name: @scrape_dev_name
      }
      md5  = PacerMD5.new(data: case_info_hash, table: 'info_root')
      case_info_hash[:md5_hash] = md5.hash
      case_info_hash
    end

    def case_lawyers
      petitioners = @case_detail_page.xpath("//table[@summary='Petitioners in this case']/tbody/tr/td[2][not(contains(., 'none recorded'))]").map(&:text).map(&:strip)
      respondents = @case_detail_page.xpath("//table[@summary='Respondents in this case']/tbody/tr/td[2][not(contains(., 'none recorded'))]").map(&:text).map(&:strip)

      case_lawyers = []
      # plantiff
      petitioners.each do |petitioner|
        name_data = petitioner.match(/(?<name>.+)( on \d{2}\/\d{2}\/\d{4})/)
        name = name_data && name_data[:name]
        name = '' if name.nil?

        firm_data = petitioner.match(/(on \d{2}\/\d{2}\/\d{4})(?<firm>.+)/)
        firm = firm_data && firm_data[:firm]
        firm = '' if firm.nil?
        case_lawyer_hash = {
          case_number: @case_id,
          defendant_lawyer: '',
          defendant_lawyer_firm:'',
          plantiff_lawyer: name,
          plantiff_lawyer_firm: firm,
          data_source_url: @data_source_url,
          scrape_frequency: 'daily',
          expected_scrape_frequency: 'daily',
          last_scrape_date: Date.today,
          next_scrape_date: Date.today + 1,
          pl_gather_task_id: '177729443',
          court_id: @court_id,
          scrape_dev_name: @scrape_dev_name
        }
        md5  = PacerMD5.new(data: case_lawyer_hash, table: 'lawyer_root')
        case_lawyer_hash[:md5_hash] = md5.hash

        case_lawyers << case_lawyer_hash

      end

      # defendant
      respondents.each do |respondent|
        name_data = respondent.match(/(?<name>.+)( on \d{2}\/\d{2}\/\d{4})/)
        name = name_data && name_data[:name]
        name = '' if name.nil?
        firm_data = respondent.match(/(on \d{2}\/\d{2}\/\d{4})(?<firm>.+)/)
        firm = firm_data && firm_data[:firm]
        firm = '' if firm.nil?
        case_lawyer_hash = {
          case_number: @case_id,
          defendant_lawyer: name,
          defendant_lawyer_firm: firm,
          plantiff_lawyer: '',
          plantiff_lawyer_firm: '',
          data_source_url: @data_source_url,
          scrape_frequency: 'daily',
          expected_scrape_frequency: 'daily',
          last_scrape_date: Date.today,
          next_scrape_date: Date.today + 1,
          pl_gather_task_id: '177729443',
          court_id: @court_id,
          scrape_dev_name: @scrape_dev_name
        }

        md5  = PacerMD5.new(data: case_lawyer_hash, table: 'lawyer_root')
        case_lawyer_hash[:md5_hash] = md5.hash

        case_lawyers << case_lawyer_hash

      end

      case_lawyers.uniq
    end

    JUDGMENT_DATES_COLUMNS = [:judgement_date, :filled_date]

    def case_judgement
      judgements = @case_detail_page.xpath('//*[@id="form"]/div[4]/table[contains(@summary, "judgments in this case")]/tbody')

      case_judgments = []
      judgements.css('tr').each do |j|
        td = j.css('td')
        judgment = {
          judgment_document_url: 'https://iapps.courts.state.ny.us/nyscef/' + td[1].css('a')[0]['href'],
          judgment_date: td[2].content,
          judgment_amount: td[3].content,
          filed_date: td[4].content,
          case_id: @case_id,
          court_id: @court_id,
          created_by: @scrape_dev_name,
          data_source_url:@data_source_url,
        }

        JUDGMENT_DATES_COLUMNS.each do |date_column|
          judgment[date_column] = Date.strptime(judgment[date_column], '%m/%d/%Y') unless judgment[date_column].nil?
        end
        case_judgments << judgment
      end
      case_judgments
    end
end

