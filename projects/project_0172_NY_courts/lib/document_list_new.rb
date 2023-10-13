class DocumentList
    def initialize(document_list_page, scrape_dev_name, data_source_url, docket_id=nil)
      #@document_list_page = document_list_page
      @document_list_page = Nokogiri::HTML(document_list_page)
      @court_name = @document_list_page.xpath("//span[@class='PageHeadingDesc']").text.strip
      @court_id = COURTS.values.select { |details| details[:court_name] == @court_name }.first[:id]
      @case_id = @document_list_page.xpath("//a[@class='skipTo']").text
      @case_id = docket_id if !@case_id.match('ot Assigned').nil?
      @scrape_dev_name = scrape_dev_name
      @data_source_url = data_source_url
    end

    def case_activities
      @document_list_page = @document_list_page.search('br').each { |br| br.replace('---!!---') }
      activities = @document_list_page.xpath("//table[@class='NewSearchResults']/tbody/tr")
      case_activities_array = []
      activities.each do |activity|

        activity_pdf = activity.xpath("td[2]/a")[0].nil? ? nil : 'https://iapps.courts.state.ny.us/nyscef/' + (activity.xpath("td[2]/a")[0]['href']).to_s

        activity_type = activity.xpath("td[2]").text.split('---!!---')[0]
        case_activity_hash = {
          case_id: @case_id,
          activity_date: activity.xpath("td[3]").text.scan(/\d{2}\/\d{2}\/\d{4}/).first,
          activity_decs: activity.xpath("td[2]").text.gsub('---!!---',"\t ").strip,
          activity_type: activity_type.strip(),
          activity_pdf: activity_pdf,
          data_source_url: @data_source_url,

          court_id: @court_id,
          created_by: @scrape_dev_name
        }
        case_activity_hash[:activity_date] = Date.strptime(case_activity_hash[:activity_date], '%m/%d/%Y') unless case_activity_hash[:activity_date].nil?
        md5  = PacerMD5.new(data: case_activity_hash, table: 'activities_root')
        case_activity_hash[:md5_hash] = md5.hash

        case_activities_array << case_activity_hash
      end
      case_activities_array
    end
end

