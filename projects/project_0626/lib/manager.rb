# frozen_string_literal: true

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
    @files = peon.give_list.sort.map { |file| file} if options[:store]

    if options[:single].nil? && options[:store]
      part  = @files.size / options[:instances] + 1
      @files = @files[(options[:instance] * part)...((options[:instance] + 1) * part)]
    elsif options[:single].nil? && options[:download]
      part  = @letters.size / options[:instances] + 1
      @letters = @letters[(options[:instance] * part)...((options[:instance] + 1) * part)]
    end
  end

  def download
    @letters.each_with_index do |letters, index|
      count = 0
      begin 
        scraper = Scraper.new
        parser = Parser.new(scraper.main_page)
        params = parser.parse_main_page
        params.merge!('ctl00$ContentPlaceHolder1$txtCivInqName' => "#{letters}")
        params.merge!('ctl00$ContentPlaceHolder1$ddlCityTown' => ' ALL TOWNS', 'ctl00$ContentPlaceHolder1$btnSubmit' => 'Search')
        content = scraper.search_page(params)
      rescue => e
        @logger.debug(e.full_message)
        count +=1
        retry if count < 5
        @logger.debug(content)
      end
      @logger.debug("Index:#{index},#{letters}")
      #peon.put(file: "Lawyer_Status_#{letters}.html", content: content)
      parser = Parser.new(content)
      page_count = parser.check_count_page
      @keeper.data_arr = parser.parse_list
      @keeper.store_data
      if page_count > 1
        (2..page_count).each do |page|
          retries = 0
          begin
            @logger.debug("Page: #{page}")
            params = parser.parse_main_page
            params.delete("__LASTFOCUS")
            params.merge!('__EVENTTARGET' => "ctl00$ContentPlaceHolder1$GVDspCivInq", "__EVENTARGUMENT" => "Page$#{page}")
            params.merge!('ctl00$ContentPlaceHolder1$ddlCityTown' => ' ALL TOWNS')
            next_page = scraper.search_page(params)
            parser = Parser.new(next_page)
          rescue => e
            @logger.debug(e.full_message)
            retries +=1
            retry if retries < 5
            @logger.debug(next_page)
          end
          @keeper.data_arr = parser.parse_list
          @keeper.store_data
        end
      end

    end
    @keeper.update_delete_status
    clear_all
    @keeper.finish
  end

  def store
    @files.each do |file|
      parser = Parser.new(peon.give(file: file))
      @keeper.data_arr = parser.parse_list
      @keeper.store_data
      clear(file)
    end
    @keeper.update_delete_status
    @keeper.finish
  end

  def clear_all
    time = Time.now.strftime("%Y_%m_%d")
    trash_folder = "Lawyer_Status_jud_ct_gov_trash_#{time}"
    peon.list.each do |file|
      peon.move(file: file, to: trash_folder)
    end
  end

  def clear(file)
    time = Time.now.strftime("%Y_%m_%d")
    trash_folder = "Lawyer_Status_jud_ct_gov_trash_#{time}"
    peon.move(file: file, to: trash_folder)
  end
end
