# frozen_string_literal: true

require_relative '../lib/connect'
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(args)
    super
    @letters = ("A".."Z").map { |item| ("A".."Z").map {|el| item + el} }.flatten
    @from_year = 2018
    @from_year = args[:start] if args[:start].present?
    @to_year = (Time.now.strftime("%Y").to_i)
    @first_month = 1
    @last_month = 12
    @first_year = "#{@first_month}/1/#{@from_year}"
    @last_year = "#{@last_month}/31/#{@to_year}"
    @scraper = Scraper.new(args) #unless args[:store]
    @keeper = Keeper.new(args)
    if args[:update]
      #last_date = IlLcCaseInfo.select(:case_filed_date).where.not(case_filed_date: nil ).order(:case_filed_date).pluck(:case_filed_date).last
      #date = ((Date.parse(last_date)) - 9).strftime("%Y-%m-%d")
      #date = date.split('-')
      #@first_year = "#{date[1]}/#{date[2]}/#{date[0]}"
      year = (Time.now.strftime("%Y").to_i)
      @first_year = "#{@first_month}/1/#{year}"
      @from_year = year
    end
  end

  def download_person
    business_name = ""
    @letters.each do |letter|
      loop_method(letter.first, letter.last, business_name, "", "")
    end
  end

  def download_business
    @letters.each do |letter|
      @business_name = "#{letter.first}#{letter.last}%"
      loop_method("","", @business_name, @first_year, @last_year)
    end
  end

  def loop_method(let_first_name, let_last_name, business_name, first_year, last_year)
    @scraper.main_page
    page = @scraper.search(let_first_name, let_last_name, business_name, first_year, last_year, '')
    if page.css("span[class='error-message']").text.present?
      @all_records = page.css("span[class='error-message']").text.split('.').first.scan(/\d+/).join.to_i
      unless @all_records.zero?
        (@from_year..@to_year).each do |year|
          from_year = year
          to_year = year
          first_month = 1
          loop do 
            last_month = first_month + 1
            loop_first_year = "#{first_month}/1/#{from_year}"
            loop_last_year = "#{last_month}/1/#{to_year}"
            loop_last_year = "12/31/#{to_year}" if last_month == 13
            loop_method(let_first_name, let_last_name, business_name, loop_first_year, loop_last_year)
            first_month += 1
            break if first_month > 12
          end
        end
      end
    else
      parser = Parser.new('')
      @keeper.store_index(parser.parse_index(page))
      records = @scraper.num_records
      if records > 25 
        !(records%25).zero? ? page_count = records/25 : page_count = records/25 -1
        page_count.times do 
          @keeper.store_index(parser.parse_index(@scraper.index_page))
        end
      end
    end 
  end

  def check_balance(args)
    count = IlLcCaseIndex.count unless args[:store] || args[:store_and_update]
    count = peon.give_list.size if args[:store] || args[:store_and_update]
    balance = @scraper.captcha
    if (count * 0.003) > balance
      Hamster.report(to: 'D053YNX9V6E', message: "442: Balance(#{balance}) is not enough to process #{count} records!")
      @logger.debug("Balance(#{balance}) is not enough to process #{count} records!")
      exit 1
    end
  end

  def download_case(args)
    case_id = IlLcCaseIndex.select(:case_id).pluck(:id, :case_id).sort
    case_id.each do |row|
      @logger.debug("Id in table:" + row.first.to_s)
      @scraper.main_page
      @scraper.search('', '', '', '', '', row.last)
      check_case_page
    end
    @keeper.update_delete_status unless args[:update]
    @keeper.update_delete_status_if_op_update if args[:update]
    clear_all
    IlLcCaseIndex.connection.execute("TRUNCATE TABLE il_lc_case_index")
    @keeper.finish unless args[:update]
    @keeper.update if args[:update]
  end

  def check_case_page
    detail_content = @scraper.url_encoded_query('0')
    if detail_content.nil?
      @logger.debug("Case not exist!")
    elsif detail_content.first.css("span[id='caseSelectPanel:recaptcha:caseSelectPanel:secureText']").present? || detail_content.first.css('title').text.include?("HTTP Status 500 – Internal Server Error")
      @logger.debug("Status 500 – Internal Server Error")
      check_case_page
    else
      store_to_db(detail_content.last)
    end
  end

  def store_to_db(file)
    parser = Parser.new(peon.give(file: file))
    @keeper.data_hash = parser.detail_data
    @keeper.store_info
    @keeper.party
    @keeper.activities
    @keeper.judgment
    @keeper.store_all
  end

  def store(args)
    peon.give_list.each do |file|
      store_to_db(file)
      clear(file)
    end
    @keeper.update_delete_status unless args[:store_and_update]
    @keeper.update_delete_status_if_op_update if args[:store_and_update]
    @keeper.finish unless args[:store_and_update]
    @keeper.update if args[:store_and_update]
  end

  def clear_all
    time = Time.now.strftime("%Y_%m_%d").split('_').join('_')
    trash_folder = "Lake_County_Illinois_trash_#{time}"
    peon.list.each do |file|
      peon.move(file: file, to: trash_folder)
    end
  end

  def clear(file)
    time = Time.now.strftime("%Y_%m_%d").split('_').join('_')
    trash_folder = "Lake_County_Illinois_trash_#{time}"
    peon.move(file: file, to: trash_folder)
  end
end
