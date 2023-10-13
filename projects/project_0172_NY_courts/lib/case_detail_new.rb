

class CaseDetail < Hamster::Scraper

  attr_reader :court_id, :case_id

  DIVIDED_STRING = '--!!--'

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
      petitioners = @case_detail_page.xpath("//table[@summary='Petitioners in this case']/tbody/tr/td[2]").map(&:text).map(&:strip)
      respondents = @case_detail_page.xpath("//table[@summary='Respondents in this case']/tbody/tr/td[2]").map(&:text).map(&:strip)
      non_lawyer_p = @case_detail_page.xpath("//table[@summary='Petitioners in this case']/tbody/tr/td[1]").map(&:text).map(&:strip)
      non_lawyer_r = @case_detail_page.xpath("//table[@summary='Respondents in this case']/tbody/tr/td[1]").map(&:text).map(&:strip)

      case_parties = []
      petitioners.each do |petitioner|
        petitioner.split(DIVIDED_STRING+DIVIDED_STRING).each do |p|
          case_party_hash = parse_parties(p.strip, 'plantiff')
          case_parties << case_party_hash if !case_party_hash.empty?
        end

      end

      respondents.each do |respondent|
        respondent.split(DIVIDED_STRING+DIVIDED_STRING).each do |r|
          case_party_hash = parse_parties(r.strip, 'defendant')
          case_parties << case_party_hash if !case_party_hash.empty?
        end

      end

      non_lawyer_p.each do |non_lawyer|
        case_party_hash = parse_non_party(non_lawyer, 'plantiff')
        case_parties << case_party_hash if !case_party_hash.empty?
      end

      non_lawyer_r.each do |non_lawyer|
        case_party_hash = parse_non_party(non_lawyer, 'defendant')
        case_parties << case_party_hash if !case_party_hash.empty?
      end
      case_parties
    end

    def parse_parties(party_person, party_type)
      name_data = party_person.match(/(?<name>.+)( on \d{2}\/\d{2}\/\d{4})/)
      name = name_data && name_data[:name]
      return {} if name.nil?
      # firm_data = party_person.match(/(on \d{2}\/\d{2}\/\d{4})(?<firm>.+)/)
      # firm = firm_data && firm_data[:firm]
      firm = party_person.split(DIVIDED_STRING)[1..].join('\n')
      case_party_hash = {
        case_id: @case_id,
        court_id:   @court_id,

        party_name:   name,
        party_type:   party_type,
        law_firm:     firm,
        is_lawyer:    1,
        party_description:nil,

        data_source_url: @data_source_url,
        created_by: @scrape_dev_name
      }

      md5_info = MD5Hash.new(table: :party)
      case_party_hash[:md5_hash] = md5_info.generate(case_party_hash)
      case_party_hash
    end

    def parse_non_party(party_person, party_type)
      name = party_person.split('\n')[0]
      case_party_hash = {
        case_id:  @case_id,
        court_id: @court_id,

        party_name: name,
        party_type: party_type,
        law_firm:     nil,
        is_lawyer:0,
        party_description: party_person,

        data_source_url: @data_source_url,
        created_by: @scrape_dev_name
      }

      md5_info = MD5Hash.new(table: :party)
      case_party_hash[:md5_hash] = md5_info.generate(case_party_hash)
      case_party_hash
    end

    def case_info
      @case_detail_page.search('br').each { |br| br.replace(DIVIDED_STRING) }
      description = @case_detail_page.xpath("/html/body/div[3]/div[2]/form/div[4]/div[2]/span").text.split(DIVIDED_STRING)[-1].strip
      description = description[0..1500] if description.length>1800
      case_info_hash = {
        court_id: @court_id,
        case_name: @case_detail_page.xpath("//span[@class='captionText']").text.strip,
        case_id: @case_id,
        case_filed_date: @filed_date,
        case_type: @case_detail_page.xpath("//span[contains(., 'Case Type')]/strong").text.strip,
        disposition_or_status: @case_detail_page.xpath("//span[contains(., 'eFiling Status')]/strong").text.strip,
        status_as_of_date: @case_detail_page.xpath("//span[contains(., 'Case Status')]/strong").text.strip,
        judge_name: @case_detail_page.xpath("//span[contains(., 'Assigned Judge')]/strong").text.strip,
        case_description: description,
        data_source_url: @data_source_url,
        created_by: @scrape_dev_name
      }

      [:judge_name,:disposition_or_status,:status_as_of_date].each do |key|
        if case_info_hash[key].strip==''
          case_info_hash[key] = nil
        end
      end
      #md5  = PacerMD5.new(data: case_info_hash, table: 'info')
      md5_info = MD5Hash.new(table: :info)
      case_info_hash[:md5_hash] = md5_info.generate(case_info_hash)
      case_info_hash
    end


    JUDGMENT_DATES_COLUMNS = [:judgment_date, :filled_date]

    def case_judgement
      judgments = @case_detail_page.xpath('//*[@id="form"]/div[4]/table[contains(@summary, "judgments in this case")]/tbody')

      case_judgments = []
      judgments.css('tr').each do |j|
        td = j.css('td')

        judgment = {
          judgment_document_url: 'https://iapps.courts.state.ny.us/nyscef/' + td[1].css('a')[0]['href'],
          activity_type: td[1].css('a')[0].content,
          judgment_date: td[2].content,
          judgment_amount: td[3].content,
          requested_amount: nil,
          filed_date: td[4].content,
          case_id: @case_id,
          court_id: @court_id,
          created_by: @scrape_dev_name,
          data_source_url:@data_source_url,
        }

        JUDGMENT_DATES_COLUMNS.each do |date_column|
          judgment[date_column] = Date.strptime(judgment[date_column], '%m/%d/%Y') unless judgment[date_column].nil?
        end

        md5_info = MD5Hash.new(columns: %w[court_id case_id activity_type judgment_date judgment_amount filed_date])
        judgment[:md5_hash] = md5_info.generate(judgment)

        case_judgments << judgment
      end
      case_judgments
    end
end

