# frozen_string_literal: true

class ManagerFLSAAC < Hamster::Scraper

  def initialize(**options)
    super
    run_id_model = RunId.new(FLSAACCaseRuns)
    @run_id = run_id_model.last_id
    @instance = options[:instance]
    @peon = Peon.new(storehouse)
    case
    when options[:parties_download]
      run_id_model.finish
      parties_download
    when options[:parties_parse]
      parties_parse
    when options[:cases_download]
      cases_download
    when options[:update]
      @update = 1
      days = options[:days].is_a?(Integer) ? options[:days] : 8
      cases_update(days_back: days)
    when options[:parties]
      run_id_model.finish
      parties_download rescue logger.error 'Parties download failed'
      parties_parse rescue logger.error 'Parties parse failed'
      cases_download rescue logger.error 'Cases download failed'
    end
  end

  COURTS = ['sa','1','2','3','4','5','6']

  def parties_download
    scraper = ScraperFLSAAC.new()
    COURTS.each do |court|
      ('A'..'Z').each do |letter|
        ['Party', 'Attorney'].each do |type|
          parties_page = scraper.parties(court:court,letter:letter, type:type)
          @peon.put(content:parties_page, file: "#{type}_#{court}_#{letter}", subfolder: "parties/")
        end
      end
    end
  end

  def parties_parse
    parser = ParserFLSAAC.new()
    keeper = KeeperFLSAAC.new()
    md5_hash_class = MD5Hash.new(columns:
                               %w[party_last_name party_first_name party_middle_name party_type party_link case_counter court_id]
    )
    @peon.give_list(subfolder: "parties/").each do |filename|
      type, court, letter = filename.split('_')
      log("#{type}, #{court}, #{letter}")
      file = @peon.give(file: filename, subfolder: "parties/")
      parties = parser.parties(file, court:court, party_type:type)
      new_parties = []
      parties_md5_hash = []
      parties.each do |party|
        parties_md5_hash.push(md5_hash_class.generate(party))
        party[:md5_hash] = parties_md5_hash[-1]
        party[:run_id] = @run_id
        party[:touched_run_id] = @run_id
        new_parties << party
        if new_parties.size > 5000
          keeper.insert_parties_raw(new_parties)
          keeper.update_run_id_parties_raw(parties_md5_hash, @run_id)
          new_parties = []
          parties_md5_hash = []
        end
      end
      keeper.insert_parties_raw(new_parties)
      keeper.update_run_id_parties_raw(parties_md5_hash, @run_id)
    end
    keeper.mark_deleted_parties_raw(@run_id)
  end

  def cases_download
    keeper = KeeperFLSAAC.new()
    scraper = ScraperFLSAAC.new()
    parser = ParserFLSAAC.new()
    limit = 1000
    page = 0
    court_id = get_court_id
    loop do
      parties = keeper.parties_raw(offset: page*limit, limit: limit, court_id:court_id)
      keeper.close_connection
      parties.each do |party|
        begin
          party_page = scraper.get_page(party[:party_link])
          cases = parser.party_cases(party_page, party[:court_id])
        rescue => e
          log(e)
          next
        end
        parties_to_db = []
        existed_cases = keeper.existed_case(court_id: party[:court_id], case_ids: cases.map{|c| c[:case_id]})
        cases.each do |case_record|
          party_to_db = parser.info_to_party(case_record[:case_id], party)
          logger.info party_to_db
          if !existed_cases.include?(case_record[:case_id])
            case_page = scraper.get_page(case_record[:data_source_url])
            full_case = parser.case_page(case_page, case_record)
            unless full_case.empty?
              full_case[:party] = party_to_db
              put_in_db(full_case)
            else
              parties_to_db << party_to_db
            end
          else
            parties_to_db << party_to_db
          end
        end
        save_party_to_case(parties_to_db) unless parties_to_db.empty?
        party.update(done: true, touched_run_id: @run_id)
      end
      break if parties.empty?

    end
  end

  def cases_update(days_back: 30)
    today = Date.today

    while days_back > 0
      date = today - days_back
      cases_update_date(date)
      days_back -= 1
    end
  end


  private

  def cases_update_date(date)
    scraper = ScraperFLSAAC.new()
    parser = ParserFLSAAC.new()
    get_court_id.each do |court_id|
      date_filed_case_page = scraper.cases_date_filed(court_id: court_id, date: date)
      cases = parser.cases_date_filed(date_filed_case_page, court_id)
      #case_ids = cases.map{|c| c[:case_id]}
      saved_page = [] # KeeperFLSAAC.existed_cases_by_case_id(case_ids: case_ids)
      cases.each do |case_record|
        next if saved_page.include?(case_record[:data_source_url])
        case_page = scraper.get_page(case_record[:data_source_url])
        full_case = parser.case_page(case_page, case_record)
        # if saved_page.include?(case_record[:case_id])
        #   full_case[:info] = nil
        # end
        put_in_db(full_case) unless full_case.empty?
        saved_page.push(case_record[:data_source_url])
      end
    end
  end

  def get_court_id
    court_ids = [310,415,416,417,418,419,420]
    if @instance.is_a?(Integer)
      [court_ids[@instance%7]]
    else
      court_ids
    end
  end

  def put_in_db(full_case)
    keeper = KeeperFLSAAC.new()
    md5_classes = {
      :info => MD5Hash.new(columns: %w[court_id case_id case_name case_filed_date case_type status_as_of_date disposition_or_status case_description judge_name lower_court_id lower_case_id ]),
      :party => MD5Hash.new(columns: %w[court_id case_id is_lawyer party_name party_type party_law_firm party_address party_description]),
      :activities => MD5Hash.new(columns: %w[court_id case_id activity_date activity_type activity_desc file]),
      :additional_info => MD5Hash.new(columns: %w[court_id case_id lower_court_name lower_case_id lower_link lower_judge_name lower_judgement_date]),
    }

    unless full_case[:info].nil?
      if full_case[:info][:case_filed_date].nil?
        full_case[:info][:case_filed_date] = Date.today
        full_case[:activities].each do |activity|
          if full_case[:info][:case_filed_date] > activity[:activity_date]
            full_case[:info][:case_filed_date] = activity[:activity_date]
          end
        end
      end

      full_case[:info].merge!({
        :md5_hash => md5_classes[:info].generate(full_case[:info]),
        :run_id => @run_id,
        :touched_run_id => @run_id,
      })
    end

    unless full_case[:party].nil?
      full_case[:party].merge!({
          :md5_hash => md5_classes[:party].generate(full_case[:party]),
          :run_id => @run_id,
          :touched_run_id => @run_id,
        })
    end

    activity_md5_hashes = []
    full_case[:activities].map do |activity|
      activity.merge!({
        :md5_hash => md5_classes[:activities].generate(activity),
        :run_id => @run_id,
        :touched_run_id => @run_id,
      })
      activity_md5_hashes.push(activity[:md5_hash])
    end

    full_case[:relations_activity] = save_pdf(full_case)

    additional_info_md5_hashes = []
    full_case[:additional_info].map do |additional_info|
      additional_info.merge!({
        :md5_hash => md5_classes[:additional_info].generate(additional_info),
        :run_id => @run_id,
        :touched_run_id => @run_id,
      })
      additional_info_md5_hashes.push(additional_info[:md5_hash])
    end
    md5_hashes = {
      info: full_case[:info][:md5_hash],
      #party: full_case[:party][:md5_hash],
      activities: activity_md5_hashes,
      additional_info: additional_info_md5_hashes
    }

    keeper.insert_case(full_case, update: @update)
    keeper.update_deleted_case(full_case[:info], md5_hashes, @run_id, update: @update)
  end

  def save_party_to_case(parties)
    party_md5_class = MD5Hash.new(columns: %w[court_id case_id is_lawyer party_name party_type party_law_firm party_address party_description])
    parties.map do |party|
      party.merge!({
                     :md5_hash => party_md5_class.generate(party),
                     :run_id => @run_id,
                     :touched_run_id => @run_id,
                   })
    end
    KeeperFLSAAC.insert_parties(parties)
  end

  def save_pdf(full_case)
    keeper = KeeperFLSAAC.new()
    scraper = ScraperFLSAAC.new()
    aws = AwsS3.new()
    case_id = full_case[:info][:case_id]
    court_id = full_case[:info][:court_id]

    url_on_pdfs = full_case[:activities].map{|act| act[:activity_pdf] if !act[:activity_pdf].nil?}
    existing_urls = keeper.get_existing_saved_pdfs(url_on_pdfs)
    key_start = "us_courts_expansion/#{court_id}/#{case_id}/"

    relations_activity_pdf = []

    full_case[:activities].each do |act|
      pdf_link = act[:activity_pdf]
      next if pdf_link.nil?
      if existing_urls.keys().include?(pdf_link)
        relations_activity_pdf.push({
                                      case_activities_md5: act[:md5_hash],
                                      case_pdf_on_aws_md5: existing_urls[pdf_link]
                                    }
        )
        next
      end

      pdf_body = scraper.get_page(pdf_link)
      key = key_start + pdf_link.split('/').last
      aws_link = aws.put_file(pdf_body, key, metadata=
        {
          url: pdf_link,
          case_id: case_id,
          court_id: court_id.to_s
        })

      pdf_on_aws = {
        case_id: case_id,
        court_id: court_id,
        source_type: 'activity',
        source_link: pdf_link,
        aws_link: aws_link,
        data_source_url: full_case[:info][:data_source_url]
      }
      md5_info = MD5Hash.new(columns: %w[court_id case_id source_type source_link data_source_url])
      md5_hash_string = md5_info.generate(pdf_on_aws)
      pdf_on_aws[:md5_hash] = md5_hash_string
      keeper.insert_pdf(pdf_on_aws)
      relations_activity_pdf.push({
                                    case_activities_md5: act[:md5_hash],
                                    case_pdf_on_aws_md5: md5_hash_string
                                  })
    end

    relations_activity_pdf
  end


end
