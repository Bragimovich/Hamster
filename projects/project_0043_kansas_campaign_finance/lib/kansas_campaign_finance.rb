# frozen_string_literal: true

require_relative './database_manager'
require_relative '../models/kansas_campaign_contributors'
require_relative '../models/kansas_campaign_expenditures'
require_relative '../models/kansas_campaign_finance_runs'

class KansasCampaignFinanceScrape < Hamster::Scraper
  URL = 'https://www.kssos.org/elections/cfr_viewer/cfr_examiner_contribution.aspx'
  URL_EXPEND = 'https://www.kssos.org/elections/cfr_viewer/cfr_examiner_expenditure.aspx'

  def initialize(*_)
    super
    @threads_count = 3
    @data_scraping = Date.today
    @run_id = check_run_id(@data_scraping)
  end

  def scrape_part(type, date)
    hammer = Dasher.new(using: :hammer, pc: 1, headless: true, save_path: "#{storehouse}#{type}/#{@run_id}/")
    browser = hammer.connect

    periods = generate_period(Date.strptime(date, '%Y-%m-%d')) unless date.nil? || date == ''

    periods.each do |period|
      type == 'main' ? browser.go_to(URL) : browser.go_to(URL_EXPEND)

      sleep(1)

      browser.at_css('#txtStartDate').focus.type(period[0])
      browser.at_css('#txtEndDate').focus.type(period[1])

      browser.css('input[type="submit"]').first.focus.click

      sleep 3
      browser.css('input[type="submit"]').first.focus.click
      sleep 3

      Hamster.report(to: 'Dmitiry Suschinsky', message: "Scrape part #43 - DONE #{type} #{period[0]}-#{period[1]}")
    end
    browser.quit
  rescue SystemExit, Interrupt, StandardError => e
    error_msg = e.backtrace.join("\n")
    Hamster.report(to: 'Dmitiry Suschinsky', message: "#43 - exception:\n #{error_msg}")
    browser.quit
  end

  def parse_part(type)
    file_list = []

    Dir["#{storehouse}#{type}/#{@run_id}/*"].each do |path|
      file_list.push(path) unless path.include?('DONE')
    end

    file_list.each_with_index do |path, _index|
      count_elements = []

      parsed_data = Nokogiri::HTML(open(path)) do |config|
        config.options |= Nokogiri::XML::ParseOptions::HUGE
      end

      if type == 'main'
        parsed_data.xpath('//span[starts-with(@id, "lblCandName_")]').each_with_index do |_x, index|
          count_elements.push(index)
        end
      else
        parsed_data.xpath('//span[starts-with(@id, "lblCandName_")]').each_with_index do |_x, index|
          count_elements.push(index)
        end
      end

      semaphore = Mutex.new
      threads_num = Array.new(@threads_count) do
        Thread.new do
          loop do
            number = nil
            semaphore.synchronize do
              number = count_elements.pop
            end
            break if number.nil?

            items = parsed_data.css("span[id$='_#{number}']")

            if type == 'main'
              candidate_name, contributor, address, address_2, city, state, zip,
                occupation, industry, date, type_of_tender, amount, kind_amount,
                kind_description, start_date, end_date = ''

              items.each do |item|
                case item['id']
                when /lblCandName_/
                  candidate_name = item.text
                when /lblContributor_/
                  contributor = item.text
                when /lblAddress_/
                  address = item.text
                when /lblAddress2_/
                  address_2 = item.text
                when /lblCity_/
                  city = item.text
                when /lblState_/
                  state = item.text
                when /lblZip_/
                  zip = item.text
                when /lblOccupation_/
                  occupation = item.text
                when /lblIndustry_/
                  industry = item.text
                when /lblDate_/
                  date = item.text
                when /lblTypeofTender_/
                  type_of_tender = item.text
                when /lblAmount_/
                  amount = item.text
                when /lblInKindAmount_/
                  kind_amount = item.text
                when /lblInKindDescription_/
                  kind_description = item.text
                when /lblStartDate_/
                  start_date = item.text
                when /lblEndDate_/
                  end_date = item.text
                else
                  "Error: undefine element #{item}"
                end
              end

              ks_contr = KansasCampaignFinanceContributors.new
              ks_contr.candidate_name = candidate_name
              ks_contr.contributor = contributor
              ks_contr.address = address
              ks_contr.address_2 = address_2
              ks_contr.city = city
              ks_contr.state = state
              ks_contr.zip = zip
              ks_contr.occupation = occupation
              ks_contr.industry = industry
              ks_contr.date = Date.strptime(date, "%m/%d/%Y").strftime('%Y-%m-%d') unless date.blank?
              ks_contr.type_of_tender = type_of_tender
              ks_contr.amount = amount.gsub('$', '').gsub(',', '').to_f unless amount.blank?
              ks_contr.kind_amount = kind_amount.gsub('$', '').gsub(',', '').to_f unless kind_amount.blank?
              ks_contr.kind_description = kind_description
              ks_contr.start_date = Date.strptime(start_date, "%m/%d/%Y").strftime('%Y-%m-%d') unless start_date.blank?
              ks_contr.end_date = Date.strptime(end_date, "%m/%d/%Y").strftime('%Y-%m-%d') unless end_date.blank?

              ks_contr.scrape_dev_name = 'dsuschinsky'
              ks_contr.last_scrape_date = @data_scraping
              ks_contr.next_scrape_date = @data_scraping + 7
              ks_contr.expected_scrape_frequency = 'weekly?'
              ks_contr.scrape_status = 'active'
              ks_contr.run_id = @run_id

              db_row = KansasCampaignFinanceContributors.find_by(
                candidate_name: ks_contr.candidate_name,
                contributor: ks_contr.contributor,
                date: ks_contr.date,
                amount: ks_contr.amount,
                kind_amount: ks_contr.kind_amount,
                kind_description: ks_contr.kind_description,
                start_date: ks_contr.start_date,
                end_date: ks_contr.end_date,

                city: ks_contr.city,
                state: ks_contr.state,
                zip: ks_contr.zip,
                address: ks_contr.address,
                address_2: ks_contr.address_2,

                is_deleted: false
              )

              begin
                if db_row.blank?
                  # new record
                  DatabaseManager.save_item(ks_contr)
                elsif check_record_equality_contr(ks_contr, db_row)
                  # existing record
                  db_row.run_id = @run_id
                  DatabaseManager.save_item(db_row)
                  next
                else
                  # updated record
                  db_row.is_deleted = true
                  db_row.run_id = @run_id
                  DatabaseManager.save_item(db_row)
                  DatabaseManager.save_item(ks_contr)
                end
              rescue ActiveRecord::ActiveRecordError => e
                @logger.error(e)
                raise
              end
            else
              candidate_name, recipient, address, address_2, city, state, zip,
                date, expenditure_description, amount, period_start_date, period_end_date = ''

              items.each do |item|
                case item['id']
                when /lblCandName_/
                  candidate_name = item.text
                when /lblContributor_/
                  recipient = item.text
                when /lblAddress_/
                  address = item.text
                when /lblAddress2_/
                  address_2 = item.text
                when /lblCity_/
                  city = item.text
                when /lblState_/
                  state = item.text
                when /lblZip_/
                  zip = item.text
                when /lblDate_/
                  date = item.text
                when /lblTypeofTender_/
                  expenditure_description = item.text
                when /lblAmount_/
                  amount = item.text
                when /lblStartDate_/
                  period_start_date = item.text
                when /lblEndDate_/
                  period_end_date = item.text
                else
                  "Error: undefine element #{item}"
                end
              end

              ks_expend = KansasCampaignFinanceExpenditures.new
              ks_expend.candidate_name = candidate_name
              ks_expend.recipient = recipient
              ks_expend.address = address
              ks_expend.address_2 = address_2
              ks_expend.city = city
              ks_expend.state = state
              ks_expend.zip = zip
              ks_expend.date = Date.strptime(date, "%m/%d/%Y").strftime('%Y-%m-%d') unless date.blank?
              ks_expend.expenditure_description = expenditure_description
              ks_expend.amount = amount.gsub('$', '').gsub(',', '').to_f unless amount.blank?
              ks_expend.period_start_date = Date.strptime(period_start_date, "%m/%d/%Y").strftime('%Y-%m-%d') unless period_start_date.blank?
              ks_expend.period_end_date = Date.strptime(period_end_date, "%m/%d/%Y").strftime('%Y-%m-%d') unless period_end_date.blank?

              ks_expend.scrape_dev_name = 'Dmitry Sushchinsky'
              ks_expend.last_scrape_date = @data_scraping
              ks_expend.next_scrape_date = @data_scraping + 7
              ks_expend.expected_scrape_frequency = 'weekly?'
              ks_expend.scrape_status = 'active'
              ks_expend.run_id = @run_id

              db_row = KansasCampaignFinanceExpenditures.find_by(
                candidate_name: ks_expend.candidate_name,
                recipient: ks_expend.recipient,
                date: ks_expend.date,
                amount: ks_expend.amount,
                period_start_date: ks_expend.period_start_date,
                period_end_date: ks_expend.period_end_date,

                city: ks_expend.city,
                state: ks_expend.state,
                zip: ks_expend.zip,
                address: ks_expend.address,
                address_2: ks_expend.address_2,

                is_deleted: false
              )

              begin
                if db_row.blank?
                  # new record
                  DatabaseManager.save_item(ks_expend)
                elsif check_record_equality_expend(ks_expend, db_row)
                  # existing record
                  DatabaseManager.save_item(db_row)
                  next
                else
                  # updated record
                  db_row.is_deleted = true
                  DatabaseManager.save_item(db_row)
                  DatabaseManager.save_item(ks_expend)
                end
              rescue ActiveRecord::ActiveRecordError => e
                Hamster.report(to: 'Dmitiry Suschinsky', message: "Parse Error #43\n#{e}")
                raise
              end
            end
          end
        end
      end
      threads_num.each(&:join)

      filename = path.scan(%r{#{Regexp.escape(storehouse)}#{type}/#{@run_id}/(\w+\S+\s\S+)$})

      if File.exist?(path) && filename[0].class != NilClass
        File.rename(path, path.gsub(filename[0][0].to_s, "DONE_#{filename[0][0]}"))
        Hamster.report(to: 'Dmitiry Suschinsky', message: "Parse part #43 - DONE #{filename}")
      end
    end
  rescue SystemExit, Interrupt, StandardError => e
    error_msg = e.backtrace.join("\n")
    Hamster.report(to: 'Dmitiry Suschinsky', message: "#43 PARSE PART - exception:\n #{error_msg}")
  end

  def rename_files(type)
    file_list = []

    Dir["#{storehouse}/#{type}/#{@run_id}/*"].each do |path|
      file_list.push(path) if path.include?('DONE')
    end

    file_list.each do |path|
      File.rename(path, path.gsub('DONE_', '')) if File.exist?(path)
    end
  end

  def generate_period(start_date)
    i = 1
    periods = []
    6.times do
      date = start_date.prev_month(i)
      i += 1
      periods.push(["#{Date.civil(date.year, date.month, 1)}",
                    "#{Date.civil(date.year, date.month, -1)}"
                   ])
    end
    periods
  end

  def check_run_id(date)
    run = KansasCampaignFinanceRuns.find_by(
      last_scrape_date: date
    )

    begin
      if run.blank?
        # new record
        ks_runs = KansasCampaignFinanceRuns.new
        ks_runs.last_scrape_date = date
        DatabaseManager.save_item(ks_runs)
      end
    rescue ActiveRecord::ActiveRecordError => e
      Hamster.report(to: 'Dmitiry Suschinsky', message: "Run ERROR #43  #{e}")
      raise
    end

    KansasCampaignFinanceRuns.last.id
  end

  def check_record_equality_contr(new_row, row)
    new_row.candidate_name == row.candidate_name &&
      new_row.contributor == row.contributor &&
      new_row.date == row.date &&
      new_row.amount == row.amount &&
      new_row.kind_amount == row.kind_amount &&
      new_row.start_date == row.start_date &&
      new_row.end_date == row.end_date &&
      new_row.city == row.city &&
      new_row.state == row.state &&
      new_row.zip == row.zip &&
      new_row.address == row.address &&
      new_row.address_2 == row.address_2 &&
      new_row.is_deleted == row.is_deleted
  end

  def check_record_equality_expend(new_row, row)
    new_row.candidate_name == row.candidate_name &&
      new_row.recipient == row.recipient &&
      new_row.date == row.date &&
      new_row.amount == row.amount &&
      new_row.period_start_date == row.period_start_date &&
      new_row.period_end_date == row.period_end_date &&
      new_row.city == row.city &&
      new_row.state == row.state &&
      new_row.zip == row.zip &&
      new_row.address == row.address &&
      new_row.address_2 == row.address_2 &&
      new_row.is_deleted == row.is_deleted
  end
end
