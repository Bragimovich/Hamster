# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'
require_relative 'shared_progress'
require_relative 'slack_reporter'

class Manager < Hamster::Scraper
  def initialize(options)
    super

    @options = options
    @scraper = Scraper.new
    @parser  = Parser.new
    @sh_prog = SharedProgress.new(storehouse)

    @keeper = Keeper.new(
      max_buffer_size: @options[:buffer],
      run_model:       'RemaxHomeListingsRun'
    )
  end

  def run
    skip_delete = @options.fetch(:skipdelete, false)
    master_inst = @options.fetch(:master, false)
    slave_num   = @options.fetch(:slave, 0)

    if master_inst
      zip_code = verify_progress_item(@sh_prog.pick_next_item(false), false)
      if zip_code.nil?
        zip_codes = all_zip_codes
        @sh_prog.store_items(zip_codes)
      end
    else
      retry_count = 0
      while true
        zip_code = verify_progress_item(@sh_prog.pick_next_item(false), false)
        break unless zip_code.nil?

        retry_count += 1
        if retry_count > 10
          SlackReporter.report(message: "Slave #{slave_num}: Master is not ready yet.")
          return
        end

        sleep(360)
      end
    end

    while true
      zip_code = verify_progress_item(@sh_prog.pick_next_item)
      break if zip_code.nil?

      @completed_ids = []
      logger.info "Working on Zip code #{zip_code}"
      run_for_zip_code(zip_code, @keeper.zip_last_modification(zip_code))

      @keeper.mark_deleted(zip_code) unless skip_delete
    end

    @keeper.flush
    @keeper.finish if master_inst
  rescue Exception => e
    cause_exc = e.cause || e
    unless cause_exc.is_a?(::Mysql2::Error) || cause_exc.is_a?(::ActiveRecord::ActiveRecordError)
      @keeper.flush rescue nil
    end
    raise e
  end

  private

  def all_zip_codes
    start_html  = @scraper.get_content('https://www.remax.com/')
    state_links = @parser.parse_start_page(start_html)

    if state_links.nil? || state_links.size.zero?
      logger.info 'No available states.'
      raise 'No available states.'
    else
      logger.info state_links
    end

    state_links.map do |state_link|
      state_html = @scraper.get_content(state_link)
      @parser.parse_state_page(state_html)
    end
    .flatten
    .sort
  end

  def run_for_zip_code(zip_code, last_modif = nil)
    total_count  = 0
    batch_size   = 240
    all_listings = []

    while true
      payload = {
        'count'            => batch_size,
        'listingLoadLevel' => 'WebSearch',
        'offset'           => total_count,
        'sorts'            => [ { 'modificationTimestamp' => 'desc' } ],
        'terms'            => { 'bPropertyType' => 'For Sale', 'zipCodeId' => [ "#{zip_code}" ] }
      }

      listings_json =
        @scraper.post_payload(
          'https://public-api-gateway-prod.kube.remax.booj.io/listings/search/run/',
          JSON.generate(payload),
          [404, 500]
        )
      break if listings_json.nil?

      fetch_count, listings = @parser.parse_listings_json(listings_json)
      all_listings += listings
      total_count  += fetch_count

      break if fetch_count < batch_size
    end

    upd_listings, keep_listings =
      if last_modif.nil?
        [all_listings, []]
      else
        upd_res = all_listings.select do |listing|
          ts = listing[:modify_timestamp]
          ts.nil? ? true : ts >= last_modif
        end
        keep_res = all_listings.reject do |listing|
          ts = listing[:modify_timestamp]
          ts.nil? ? true : ts >= last_modif
        end

        [upd_res, keep_res]
      end

    unless keep_listings.size.zero?
      keep_prop_ids = keep_listings.map { |l| [l[:property_id], l[:modify_timestamp]] }
      @keeper.touch(keep_prop_ids)
    end

    logger.info "Updating #{upd_listings.size} out of #{all_listings.size} properties."

    upd_listings.each do |listing_base|
      next if @completed_ids.include?(listing_base[:property_id])

      # Get property details
      listing = {
        address:          listing_base[:address],
        city:             listing_base[:city],
        property_id:      listing_base[:property_id],
        modify_timestamp: listing_base[:modify_timestamp],
        state:            listing_base[:state],
        zip:              listing_base[:zip]
      }

      listing_url  = "https://www.remax.com/api-v2/properties/property/#{listing_base[:property_id]}"
      listing_json = @scraper.get_content(listing_url, :json, [404])
      next if listing_json.nil?

      listing   = listing.merge(@parser.parse_listing_json(listing_json))
      full_addr = "#{listing[:address]}, #{listing[:city]}, #{listing[:state]} #{listing[:zip]}"
      data_url  = "https://www.remax.com/#{listing[:state].downcase}/#{listing[:city].downcase}/home-details/#{full_addr.parameterize}/#{listing[:property_id]}/#{listing[:ouid]}/#{listing[:listing_id]}"
      listing[:data_source_url] = data_url

      @keeper.save_data('RemaxHomeListing', listing)

      trans_url  = "https://www.remax.com/api-v2/properties/property/#{listing[:property_id]}/transactions"
      trans_json = @scraper.get_content(trans_url, :json, [404])
      next if trans_json.nil?

      trans_data = @parser.parse_transactions_json(trans_json)

      trans_data.each do |trans|
        trans[:property_id]     = listing[:property_id]
        trans[:property_zip]    = listing[:zip]
        trans[:data_source_url] = data_url

        @keeper.save_data('RemaxHomePropertyHistory', trans)
      end

      @completed_ids << listing_base[:property_id]
    end
  end

  def verify_progress_item(item, report = true)
    return nil unless item.instance_of?(Array)

    total_count  = item[0]
    remain_count = item[1]
    item_value   = item[2]

    return nil if total_count.nil? || total_count <= 0
    return nil if remain_count.nil? || remain_count <= 0
    return nil if item_value.nil?

    if report
      done_cnt_before = total_count - remain_count
      done_cnt_after  = done_cnt_before + 1
      done_per_before = (10 * done_cnt_before / total_count).to_i
      done_per_after  = (10 * done_cnt_after / total_count).to_i

      if done_per_before < done_per_after
        master_inst = @options.fetch(:master, false)
        slave_num   = @options.fetch(:slave, 0)
        inst_name   = master_inst ? 'Master' : "Slave #{slave_num}"
        SlackReporter.report(message: "#{inst_name}: #{done_per_after * 10}% of zip codes picked.")
      end
    end

    item_value
  end
end
