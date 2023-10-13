# frozen_string_literal: true

require_relative '../lib/connect'
require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'


class Manager < Hamster::Harvester
  def initialize(options)
    super
    @keeper = Keeper.new(options)
    letters_arr = ("a".."z").map { |item| ("a".."z").map {|el| item + el} }.flatten
    num = 0
    num = options[:start] if options[:start].present?
    @letters = letters_arr[num..-1]
  end

  def download(options)
    @letters.each_with_index do |letter, index|
      get_main_page(options, letter)
      loop do
        begin
          result = @scraper.next_page
          break if result.size < 500
          parser = Parser.new(result)
          parser.check_session
          list = parser.offender_list
        rescue => e
          @logger.error(e.full_message)
          if e.message == "Page Session expired"
            get_main_page(options, letter)
            retry
          end
        end
        list.each_with_index do |row, index|
          retries = 0 
          begin
            content = @scraper.view_offender_page(row)
            @logger.info("Index_#{index}_let_#{letter}_row_#{row.split(':')[-2]}-#{@all_record}")
            parser = Parser.new(content.body)
            parser.check_session
          rescue => e
            if e.message == "Page Session expired" || e.message ==  "Bad proxy"
              get_main_page(options, letter)
              @scraper.next_page
              retries +=1 
              retry if retries < 5
            end
          end
          store_to_db(content.body)
          #peon.put(file: "Sexual_Offenders_let_#{letter}_row_#{row.split(':')[-2]}-#{@all_record}.html", content: content.body)
        end
      end
    end
    @keeper.update_delete_status
    clear_all
    @keeper.finish
  end

  def get_main_page(options, letter)
    count = 0 
    begin 
      @scraper = Scraper.new(options)
      @scraper.swap_proxy
      @scraper.main_page
      @scraper.letter = letter
      @all_record = @scraper.search_page
    rescue => e
      @logger.info(count +=1)
      @logger.error(e.full_message)
      retry if count < 5
    end
  end

  def store
    peon.give_list.each do |file|
      store_to_db(peon.give(file: file))
      clear(file)
    end
    @keeper.update_delete_status
    @keeper.finish
  end

  def store_to_db(file)
    begin
      parser = Parser.new(file)
      @keeper.data_hash = parser.parse_offender
      @keeper.store_arrestees
      @keeper.store_advance_arrestees
      @keeper.store_aliases
      @keeper.store_maskrs
      @keeper.store_victim_info
      @keeper.store_state
      @keeper.store_cities
      @keeper.store_vehicles_info
      @keeper.store_zips
      @keeper.store_addresses
      @keeper.store_arrestees_address
      @keeper.store_offense
      @keeper.store_vessel_info
      @keeper.store_mugshots
    rescue => e
      @logger.debug(e.full_message)
      @logger.debug(file)
      Hamster.report to: 'D053YNX9V6E', message: "554: store: #{file}"
    end
  end

  def clear(file)
    time = Time.now.strftime("%Y_%m_%d").split('_').join('_')
    trash_folder = "Sexual_Offenders_IL_trash_#{time}"
    peon.move(file: file, to: trash_folder)
  end

  def clear_all
    time = Time.now.strftime("%Y_%m_%d").split('_').join('_')
    trash_folder = "Lake_County_Illinois_trash_#{time}"
    peon.list.each do |file|
      peon.move(file: file, to: trash_folder)
    end
  end

  def store_img(options)
    scraper = Scraper.new(options)
    img_link = FloridaMugshots.select(:original_link).where(aws_link: nil ).pluck(:original_link, :id)
    img_link.each do |value|
      @keeper.update_aws_link(scraper.store_to_aws(value[0]), value[1])
    end
  end
end
