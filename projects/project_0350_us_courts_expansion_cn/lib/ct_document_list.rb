# frozen_string_literal: true
class CTDocumentList
  def initialize(case_detail_page, data_source_url, filed_date, scrape_dev_name, court_id, run_id)
    @document_list_page = Nokogiri::HTML(case_detail_page)

    @court_id = court_id
    if court_id == 307
      if !@document_list_page.css('span:contains("PETITION")').blank? || !@document_list_page.css('span:contains("petition")').blank?
        @case_id = 'Pet ' + @document_list_page.css("//span[id='lblAppealNo']").text.to_s.strip
      elsif !@document_list_page.css('span:contains("MOTION")') || !@document_list_page.css('span:contains("motion")')
        @case_id = 'Mot ' + @document_list_page.css("//span[id='lblAppealNo']").text.to_s.strip
      else
        @case_id = @document_list_page.css("//span[id='lblAppealNo']").text.to_s.strip
      end
    else
      @case_id = @document_list_page.css("//span[id='lblAppealNo']").text.to_s.strip
    end

    @filed_date = filed_date
    @scrape_dev_name = scrape_dev_name
    @data_source_url = data_source_url
    @run_id = run_id
    @ct_saac_case_activities = CtSaacCaseActivities

    @md5_cash_maker = {
      case_activities: MD5Hash.new(columns: %i[court_id case_id activity_date activity_desc activity_type file activity_pdf data_source_url])
    }

  end

  def connect_to_db(database = :us_court_cases)
    Mysql2::Client.new(Storage[host: :db01, db: database].except(:adapter).merge(symbolize_keys: true))
  end

  def ct_case_activities_nil?
    activities = @document_list_page.css('//table[@id="gvActivities"]').css('tr')
    activities.blank? ? true : false
  end

  def ct_case_activities
    activities = @document_list_page.css('//table[@id="gvActivities"]').css('tr')
    case_filed_date = @document_list_page.css("//span[id='lblDateFiled']").text.strip

    return nil if activities.blank?
    return nil if @case_id.blank?

    activities.shift.css('th')

    case_activities = []
    semaphore = Mutex.new
    threads_activities = Array.new(3) do
      Thread.new do
        client = connect_to_db
        loop do
          break if activities.size.zero?

          activity = nil

          semaphore.synchronize do
            activity = activities.pop
          end
          break if activity.nil?

          activity_pdf = activity.css('a').size.positive? ? activity.css('a')[0]['href'] : nil
          activity_type = activity.xpath('./td')[0].css('span').text.strip
          activity_desc = activity.xpath('./td')[4].css('span').text.strip
          if (activity_desc.include?('Transfer Case from') || activity_desc.include?('Transfer Case to')) && !activity.xpath("//a[contains(@id, '_hlnkTransferToAppeal')]").blank?
            activity_desc =
              activity.xpath('./td')[4].css('span').text.strip + ' ' +
              activity.xpath("//a[contains(@id, '_hlnkTransferToAppeal')]").text.strip
          end
          activity_date = activity.xpath('./td')[6].text.strip.blank? ? case_filed_date : activity.xpath('./td')[6].text.strip

          case_activity_hash = {
            case_id: @case_id,
            court_id: @court_id,

            activity_date: activity_date.nil? ? '' : activity_date,
            activity_desc: activity_desc,
            activity_type: activity_type,
            file: activity_pdf,

            data_source_url: @data_source_url,
            created_by: @scrape_dev_name,
            run_id: @run_id
          }

          unless case_activity_hash[:activity_date].blank?
            case_activity_hash[:activity_date] =
              Date.strptime(case_activity_hash[:activity_date],
                            '%m/%d/%Y')
          end

          hash = case_activity_hash.as_json
          md5 = @md5_cash_maker[:case_activities].generate(hash)
          case_activity_hash[:md5_hash] = md5

          query = "SELECT * FROM us_court_cases.ct_saac_case_activities
             WHERE md5_hash = '#{md5}' and deleted = 0;"
          case_activity_exist = client.query(query).to_a

          case_activity_exist_first = case_activity_exist.first

          if case_activity_exist_first.nil?
            case_activities << case_activity_hash
          elsif case_activity_exist.size == 1
            query = "UPDATE us_court_cases.ct_saac_case_activities
               SET run_id = '#{@run_id}', touched_run_id = '#{@run_id}'
               WHERE id = #{case_activity_exist_first[:id]}"
            client.query(query)
          elsif case_activity_exist.size > 1
            case_activity_exist.each_with_index do |row, index|
              query = "UPDATE us_court_cases.ct_saac_case_activities
               SET run_id = '#{@run_id}', touched_run_id = '#{@run_id}'
               WHERE id = #{row[:id]}"
              client.query(query)
            end
          end
        end
        client.close
      end
    end
    threads_activities.each(&:join)

    case_activities.uniq { |e| e[:md5_hash] }
  end
end
