# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize(options)
    super
    @check = false if options[:download_arrests_url] || options[:auto]
    @keeper = Keeper.new
    ArkansasInmatesUrl.connection.execute("TRUNCATE TABLE arkansas_inmates_url") if options[:download_arrests_url] || options[:auto]
    @county_list = connect_main_page if options[:download_arrests_url] || options[:auto]
    @county_list = @county_list.last[1..-1] if options[:download_arrests_url] || options[:auto]
    @link_list = ArkansasInmatesUrl.pluck(:data_source_url, :id) if options[:download] && options[:single].nil?

    if options[:single].nil? && options[:download_arrests_url]
      part  = @county_list.size / options[:instances] + 1
      @county_list = @county_list[(options[:instance] * part)...((options[:instance] + 1) * part)]
    elsif options[:single].nil? && options[:download]
      part  = @link_list.size / options[:instances] + 1
      @link_list = @link_list[(options[:instance] * part)...((options[:instance] + 1) * part)]
    end
  end

  def download(options)
    @link_list = ArkansasInmatesUrl.pluck(:data_source_url, :id) if options[:auto] || options[:download] || !options[:single].nil? && options[:auto]
    unless @link_list.nil? || @link_list.empty?
      @link_list.each do |link|
        retries = 0
        begin
          scraper = Scraper.new
          scraper.swap_proxy
          content = scraper.get_arrest_page(link.first)
          #peon.put(file: "Offenders_num_#{link.split("=")[1].split("&").first}.html", content: content) rescue nil
          parser = Parser.new(content)
          @logger.debug("Id: #{link.last}")
          parser.link = link.first
          parser.run_id = @keeper.run_id
          @keeper.fill_arr(parser.parse_info)
        rescue => e
          @logger.debug(e.full_message)
          @logger.debug(retries += 1)
          if (retries < 5)
            sleep retries**3
            retry
          else
            nil
          end
          Hamster.report to: 'D053YNX9V6E', message: "747: download:#{e.full_message} || #{link}"
        end

        if @keeper.full_array
          begin
            store_all
          rescue => e
            @logger.debug(e.full_message)
            @logger.debug(retries += 1)
            if (retries < 5)
              sleep retries**3
              retry
            else
              nil
            end
            Hamster.report to: 'D053YNX9V6E', message: "747: store:#{e.full_message} || #{link}"
          end
        end
      end
    else
      Hamster.report to: 'D053YNX9V6E', message: "747 List: #{@link_list.size}"
      exit 1 
    end
    store_all
    #clear_all
    @keeper.update_delete_status
    @keeper.finish
  end

  def store_all
    @keeper.store_inmates
    @keeper.store_arrests
    @keeper.store_holding_facilities_addresses
    @keeper.store_holding_facilities
    @keeper.store_inmate_ids
    @keeper.store_inmate_ids_additional
    @keeper.store_aliases
    @keeper.store_additional_info
    @keeper.store_charges
    @keeper.store_disciplinary_violations
    @keeper.store_program_achievements
    @keeper.store_mugshots
    @keeper.clear_data
  end

  def connect_main_page
    @scraper = Scraper.new
    parser = Parser.new(@scraper.main_page)
    parser.parse_main_page
  end

  def download_arrests_url
    @county_list.each do |county|
      begin
        @logger.debug(county)
        county_list = connect_main_page
        crimes_list = @scraper.search_page(county_list.first, county)
        parser = Parser.new(crimes_list)
        parser.county = county
        parser.token = county_list.first
        loop do
          next_page = parser.next_page
          @scraper.page = parser.page_number unless next_page.first.nil?
          @scraper.fix_page = true if @check
          parser = Parser.new(@scraper.view_info(next_page.first)) if @check
          @check = false
          inmate_list = parser.parse_list
          @keeper.store_url(inmate_list)
          @scraper.swap_proxy
          sleep 2
          @logger.debug(next_page)
          break if next_page.last.nil?
          parser = Parser.new(@scraper.view_info(next_page.first))
        end
      rescue *connection_error_list => e
        @logger.error(e.full_message)
        @check = true
        retry
      end
    end
    Hamster.report to: 'D053YNX9V6E', message: "747: link count #{ArkansasInmatesUrl.count}"
  end

  def connection_error_list
    [
      Mechanize::ResponseCodeError,
      Errno::ECONNRESET,
      OpenSSL::SSL::SSLError,
      SOCKSError::NotAllowed,
      Net::HTTP::Persistent::Error
    ]
  end

  def clear_all
    time = Time.now.strftime("%Y_%m_%d").split('_').join('_')
    trash_folder = "Offenders_trash_#{time}"
    peon.list.each do |file|
      peon.move(file: file, to: trash_folder)
    end
  end

  def store_img
    scraper = Scraper.new
    img_link = ArkansasMugshots.select(:original_link).where(aws_link: nil ).pluck(:original_link, :id)
    img_link.each do |value|
      @keeper.update_aws_link(scraper.store_to_aws(value[0]), value[1])
    end
  end
end
