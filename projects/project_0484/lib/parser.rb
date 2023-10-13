# frozen_string_literal: true

class Parser < Hamster::Parser
  def parse_listing_json(json)
    listing = parse_json(json)

    price = listing['listPrice'].to_i
    sqft  = listing['livingArea'].to_i
    ratio = (price.zero? || sqft.zero?) ? nil : (price / sqft).to_i

    {
      ouid:              listing['oUID'],
      listing_id:        listing['listingId'],
      total_baths:       listing['bathroomsTotalInteger'],
	    full_baths:        listing['bathroomsFull'],
	    bedrooms:          listing['bedroomsTotal'],
	    square_feet:       listing['livingArea'],
	    acres:             listing['lotSizeAcres'],
	    year_built:        listing['yearBuilt'],
	    selling_price:     listing['listPrice'],
	    status:            listing['standardStatus'],
	    cooling:           listing['cooling'].present? ? true : nil,
	    heating:           listing['heating'].present? ? true : nil,
	    hoa:               listing['associationFee'],
	    parking:           listing['parkingTotal'],
	    sq_ft_price:       ratio,
	    property_type:     listing['propertyType'],
	    property_sub_type: listing['propertySubType'],
	    listed_at_date:    parse_date(listing['listingContractDate']),
	    additional_info:   pack_listing_features(listing)
    }
  end

  def parse_listings_json(json)
    listings = parse_json(json)
    totals   = listings.dig('data', 'totalResults')
    if totals.nil?
      logger.info 'Failed to parse listings JSON.'
      logger.info json
      raise 'Failed to parse listings JSON.'
    end

    results  = listings.dig('data', 'results') || []
    org_size = results.size
    results = results.map do |res|
      geo_data = (res['geo'] || []).first
      if geo_data.nil?
        logger.info "Missing geo data for #{res['listingId']}"
        next nil
      end

      full_addr  = geo_data['displayName'] || ''
      addr_comps = full_addr.split(',')
      addr_valid = addr_comps.size >= 3

      address = nil
      state   = nil
      zip     = nil
      city    = nil

      if addr_valid
        state_zip = addr_comps[-1].strip
        city      = addr_comps[-2].strip
        address   = addr_comps[0..(addr_comps.size - 3)].join(',').strip

        match_data = state_zip.match(/^(\w{2})\s+(\d{5}(?:\-\d{4})?)$/)
        if match_data.nil? || match_data.size != 3
          addr_valid = false
        else
          state = match_data[1].strip
          zip   = match_data[2].strip

          addr_valid = false if [address, city, state, zip].any?(&:nil?)
        end
      end

      unless addr_valid
        logger.info "Invalid address (#{geo_data['displayName']}) for #{res['listingId']}"
        next nil
      end

      modify_ts = DateTime.parse(res['modificationTimestamp']).to_i rescue nil

      {
        address:          address,
        city:             city,
        modify_timestamp: modify_ts,
        state:            state,
        property_id:      res['uPI'],
	      zip:              zip
      }
    end

    [org_size, results.compact]
  end

  def parse_start_page(html)
    doc        = Nokogiri::HTML(html)
    state_tags = doc.xpath('//div[contains(@class, "state-links-section")]/span/a[starts-with(@href, "/state/")]')
    state_urls = state_tags.map { |t| "https://www.remax.com#{t[:href]}" }

    if state_urls.size.zero?
      logger.info 'Failed to parse start page.'
      logger.info html
      raise 'Failed to parse start page.'
    end

    state_urls
  end

  def parse_state_page(html)
    doc  = Nokogiri::HTML(html)
    zips = doc.xpath('//section[@data-test="state-search-links-zips"]/div[contains(@class, "state-search-links-row-items")]/span/a/text()')
    zips = zips.map { |z| z.content&.strip || nil }.compact

    if zips.size.zero?
      logger.info 'Failed to parse state page.'
      logger.info html
      raise 'Failed to parse state page.'
    end

    zips
  end

  def parse_transactions_json(json)
    trans = parse_json(json)

    trans =
      trans
        .reject { |t| t['PROP_SALEAMT'].to_i.zero? }
        .group_by { |t| parse_date(t['PropertyRecordDate']) }
        .sort_by { |dt, arr| dt.nil? ? '' : -dt }

    trans.map do |t|
      {
        date:    t[0],
        details: 'Sold',
        price:   t[1][0]['PROP_SALEAMT'],
        source:  'Public Record'
      }
    end
  end

  private

  def pack_listing_features(listing)
    features = listing['features']
    return nil if features.blank?

    res =
      features.each_with_object({}) do |feature, hash|
        d_name = feature['name']
        next if d_name.blank?

        data =
          feature['data']&.each_with_object({}) do |entry, hash|
            next unless entry['publicDisplay']
            next if entry['name'].blank?
            next if entry['value'].blank?

            hash[entry['name']] = entry['value']
          end
        next if data.blank?

        hash[d_name] = data
      end

    res.blank? ? nil : JSON.generate(res)
  end

  def parse_date(date_string)
    Date.strptime(date_string, '%Y-%m-%d').strftime('%Y-%m-%d') rescue nil
  end

  def parse_json(json)
    JSON.parse(json)
  rescue => e
    logger.info 'Failed to parse JSON.'
    logger.info json
    raise e
  end
end
