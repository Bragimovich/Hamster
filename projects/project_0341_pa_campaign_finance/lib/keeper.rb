# frozen_string_literal: true

require 'csv'

class Keeper
  def load_committees(file_path, report_date)
    validate_committees(file_path)

    client = create_client_connection
    begin
      client.query("load data local infile '#{file_path}' into table pa_campaign_finance_committees_new_csv
                    FIELDS TERMINATED BY ','
                    OPTIONALLY ENCLOSED BY '\"'
                    ESCAPED BY '\b'
                    LINES TERMINATED BY '\n'
                    (@committee_id,
                     @report_id,
                     @election_year,
                     @timestamp,
                     @cycle,
                     @ammend,
                     @terminate,
                     @filertype,
                     @filername,
                     @committee_office,
                     @committee_district,
                     @committee_party,
                     @committee_address,
                     @committee_address2,
                     @committee_city,
                     @committee_state,
                     @committee_zipcode,
                     @committee_conty,
                     @committee_phone,
                     @beginning,
                     @monetary,
                     @inkind)
                    SET committee_id = @committee_id,
                        election_year = @election_year,
                        cycle = @cycle,
                        ammend = @ammend,
                        terminate = @terminate,
                        filertype = @filertype,
                        filername = @filername,
                        committee_office = @committee_office,
                        committee_district = @committee_district,
                        committee_party = @committee_party,
                        committee_address = @committee_address,
                        committee_address2 = @committee_address2,
                        committee_city = @committee_city,
                        committee_state = @committee_state,
                        committee_zipcode = @committee_zipcode,
                        committee_conty = @committee_conty,
                        committee_phone = @committee_phone,
                        beginning = @beginning,
                        monetary = @monetary,
                        inkind = @inkind,
                        data_source_url = 'https://www.campaignfinanceonline.pa.gov/pages/CFReportSearch.aspx',
                        state = 'Pennsylvania',
                        source_agency = 'Pennsylvania Department of State',
                        source_agency_id = 645411381,
                        report_date = '#{report_date.strftime('%Y-%m-%d')}',
                        ll_scrape_dev_name = 'Anton Storchak',
                        last_scrape_date = current_date(),
                        next_scrape_date = '#{(Date.today + 7).strftime('%Y-%m-%d')}',
                        expected_scrape_frequency = 'weekly',
                        dataset_name_prefix = 'pa_campaign_finance',
                        scrape_status = 'live',
                        pl_gather_task_id = '8405',
                        created_at = now()
                ;")

      puts '###Load committees - COMPLETED###'
    ensure
      client.close
    end
  end

  def load_contributions(file_path, report_date)
    validate_contributions(file_path)

    client = create_client_connection
    begin
      client.query("load data local infile '#{file_path}' into table pa_campaign_finance_contributions_new_csv
                    FIELDS TERMINATED BY ','
                    OPTIONALLY ENCLOSED BY '\"'
                    ESCAPED BY '\b'
                    LINES TERMINATED BY '\r\n'
                    (@committee_id,
                     @report_id,
                     @election_year,
                     @timestamp,
                     @cycle,
                     @section,
                     @contributor_name,
                     @contributor_address,
                     @contributor_address2,
                     @contributor_city,
                     @contributor_state,
                     @contributor_zip,
                     @occupation,
                     @ename,
                     @eaddress1,
                     @eaddress2,
                     @ecity,
                     @estate,
                     @ezipcode,
                     @date,
                     @amount,
                     @contdate2,
                     @contamt2,
                     @contdate3,
                     @contamt3,
                     @contdesc)
                    SET committee_id = @committee_id,
                        election_year = @election_year,
                        cycle = @cycle,
                        section = @section,
                        contributor_name = @contributor_name,
                        contributor_address = @contributor_address,
                        contributor_address2 = @contributor_address2,
                        contributor_city = @contributor_city,
                        contributor_state = @contributor_state,
                        contributor_zip = @contributor_zip,
                        occupation = @occupation,
                        ename = @ename,
                        eaddress1 = @eaddress1,
                        eaddress2 = @eaddress2,
                        ecity = @ecity,
                        estate = @estate,
                        ezipcode = @ezipcode,
                        date = STR_TO_DATE(@date,'%Y%m%d'),
                        amount = @amount,
                        contdate2 = @contdate2,
                        contamt2 = @contamt2,
                        contdate3 = @contdate3,
                        contamt3 = @contamt3,
                        contdesc = @contdesc,
                        data_source_url = 'https://www.campaignfinanceonline.pa.gov/pages/CFReportSearch.aspx',
                        state = 'Pennsylvania',
                        source_agency = 'Pennsylvania Department of State',
                        source_agency_id = 645411381,
                        report_date = '#{report_date.strftime('%Y-%m-%d')}',
                        ll_scrape_dev_name = 'Anton Storchak',
                        last_scrape_date = current_date(),
                        next_scrape_date = '#{(Date.today + 7).strftime('%Y-%m-%d')}',
                        expected_scrape_frequency = 'weekly',
                        dataset_name_prefix = 'pa_campaign_finance',
                        scrape_status = 'live',
                        pl_gather_task_id = '8405',
                        created_at = now()
                ;")

      puts '###Load contributions - COMPLETED###'
    ensure
      client.close
    end
  end

  def load_expenditures(file_path, report_date)
    validate_expenditures(file_path)

    client = create_client_connection
    begin
      client.query("load data local infile '#{file_path}' into table pa_campaign_finance_expenditures_new_csv
                    FIELDS TERMINATED BY ','
                    OPTIONALLY ENCLOSED BY '\"'
                    ESCAPED BY '\b'
                    LINES TERMINATED BY '\r\n'
                    (@committee_id,
                    @report_id,
                    @election_year,
                    @timestamp,
                    @cycle,
                    @receiver,
                    @address,
                    @address2,
                    @city,
                    @state,
                    @zipcode,
                    @date,
                    @amount,
                    @expdesc)
                    SET committee_id = @committee_id,
                        election_year = @election_year,
                        cycle = @cycle,
                        receiver = @receiver,
                        address = @address,
                        address2 = @address2,
                        city = @city,
                        state = @state,
                        zipcode = @zipcode,
                        date = STR_TO_DATE(@date,'%Y%m%d'),
                        amount = @amount,
                        expdesc = @expdesc,
                        data_source_url = 'https://www.campaignfinanceonline.pa.gov/pages/CFReportSearch.aspx',
                        state = 'Pennsylvania',
                        source_agency = 'Pennsylvania Department of State',
                        source_agency_id = 645411381,
                        report_date = '#{report_date.strftime('%Y-%m-%d')}',
                        ll_scrape_dev_name = 'Anton Storchak',
                        last_scrape_date = current_date(),
                        next_scrape_date = '#{(Date.today + 7).strftime('%Y-%m-%d')}',
                        expected_scrape_frequency = 'weekly',
                        dataset_name_prefix = 'pa_campaign_finance',
                        scrape_status = 'live',
                        pl_gather_task_id = '8405',
                        created_at = now()
                ;")

      puts '###Load expenditures - COMPLETED###'
    ensure
      client.close
    end
  end

  private

  def validate_committees(file_path)
    csv = CSV.parse(File.open(file_path, &:readline).force_encoding('iso-8859-1').encode('utf-8'), liberal_parsing: true)
    raise '3 item is not date' unless Date.strptime(csv.first[3], '%Y-%m-%d').methods.include? :strftime
    raise '15 item size not equal 2' unless csv.first[15].gsub('"', '').size == 2
    raise '16 item' unless csv.first[16].gsub('"', '').count('A-Za-z') == 0
  end

  def validate_contributions(file_path)
    csv = CSV.parse(File.open(file_path, &:readline).force_encoding('iso-8859-1').encode('utf-8'), liberal_parsing: true)
    raise '3 item is not date' unless Date.strptime(csv.first[3], '%Y-%m-%d').methods.include? :strftime
    raise '10 item size not equal 2' unless csv.first[10].gsub('"', '').size == 2
    raise '19 item is not date' unless Date.strptime(csv.first[19].gsub('"', ''), '%Y%m%d').methods.include? :strftime
  end

  def validate_expenditures(file_path)
    csv = CSV.parse(File.open(file_path, &:readline).force_encoding('iso-8859-1').encode('utf-8'), liberal_parsing: true)
    raise '3 item is not date' unless Date.strptime(csv.first[3], '%Y-%m-%d').methods.include? :strftime
    raise '9 item size not equal 2' unless csv.first[9].gsub('"', '').size == 2
    raise '10 item' unless csv.first[10].gsub('"', '').count('A-Za-z') == 0
    raise '11 item is not date' unless Date.strptime(csv.first[11].gsub('"', ''), '%Y%m%d').methods.include? :strftime
  end

  def create_client_connection
    1.upto(100) do
      begin
        return Mysql2::Client.new(Storage[host: :db13, db: :pa_raw])
        # return Mysql2::Client.new(Storage[host: :db09, db: :astorchak_test])
      rescue StandardError => e
        p e
        p e.backtrace
      end

      sleep DB_RECONNECT_SLEEP
    end

    raise 'Unable create client database connection'
  end
end
