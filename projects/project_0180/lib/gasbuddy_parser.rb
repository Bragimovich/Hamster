# frozen_string_literal: true

class GasBuddyParser < Hamster::Parser

  US_STATE = {
    'Alabama' => 'AL',
    'Alaska' => 'AK',
    'America Samoa' => 'AS',
    'Arizona' => 'AZ',
    'Arkansas' => 'AR',
    'California' => 'CA',
    'Colorado' => 'CO',
    'Connecticut' => 'CT',
    'Delaware' => 'DE',
    'District of Columbia' => 'DC',
    'Federated States of Micronesia' => 'FM',
    'Florida' => 'FL',
    'Georgia' => 'GA',
    'Guam' => 'GU',
    'Hawaii' => 'HI',
    'Idaho' => 'ID',
    'Illinois' => 'IL',
    'Indiana' => 'IN',
    'Iowa' => 'IA',
    'Kansas' => 'KS',
    'Kentucky' => 'KY',
    'Louisiana' => 'LA',
    'Maine' => 'ME',
    'Maryland' => 'MD',
    'Massachusetts' => 'MA',
    'Marshall Islands' => 'MH',
    'Michigan' => 'MI',
    'Minnesota' => 'MN',
    'Mississippi' => 'MS',
    'Missouri' => 'MO',
    'Montana' => 'MT',
    'Nebraska' => 'NE',
    'Nevada' => 'NV',
    'New Hampshire' => 'NH',
    'New Jersey' => 'NJ',
    'New Mexico' => 'NM',
    'New York' => 'NY',
    'North Carolina' => 'NC',
    'North Dakota' => 'ND',
    'Northern Mariana Islands' => 'MP',
    'Ohio' => 'OH',
    'Oklahoma' => 'OK',
    'Oregon' => 'OR',
    'Palau' => 'PW',
    'Pennsylvania' => 'PA',
    'Puerto Rico' => 'PR',
    'Rhode Island' => 'RI',
    'South Carolina' => 'SC',
    'South Dakota' => 'SD',
    'Tennessee' => 'TN',
    'Texas' => 'TX',
    'Utah' => 'UT',
    'Vermont' => 'VT',
    'Virgin Island' => 'VI',
    'Virginia' => 'VA',
    'Washington' => 'WA',
    'West Virginia' => 'WV',
    'Wisconsin' => 'WI',
    'Wyoming' => 'WY'
  }

  def parse_response(response)
    json = parse_json(response)
    json["data"]["locationBySearchTerm"]
  end

  def parse_json(json_str)
    JSON.parse(json_str)
  end

  def calc_zip_md5(parsed, count, run_id)
    h = {
      latitude: parsed["latitude"],
      longitude: parsed["longitude"],
      count: count,
      run_id: run_id,
    }
    calc_md5_hash(h)
  end

  def no_stations(stations)
    stations['count'] == 0 || stations['results'].empty?
  end

  def country_not_us(stations)
    stations['results'].first['address']['country'] != 'US'
  end

  def count(stations)
    stations['count']
  end

  def no_credit_price(station_price)
    station_price[:credit_price].nil? || station_price[:credit_price] == 0
  end

  def no_cash_price(station_price)
    station_price[:cash_price].nil? || station_price[:cash_price] == 0
  end

  def parse_station(zip, s)
    station = {
      station_id: s['id'].to_i,
      station_name: s['name']&.squish.presence,
      ratings_count: s['ratingsCount'].presence,
      star_rating: s['starRating'].presence,
      phone: s['phone']&.squish.presence,
      timezone: s['timezone']&.squish.presence,
      brand_name: s['brandName']&.squish.presence,
      status: s['status']&.squish.presence,
      emergency_status: nil, # s['emergency_status']&.squish.presence,
      latitude: s['latitude'].presence,
      longitude: s['longitude'].presence,
      address_country: s.dig('address', 'country')&.squish.presence,
      address_line_1: s.dig('address', 'line1')&.squish.presence,
      address_line_2: s.dig('address', 'line2')&.squish.presence,
      address_locality: s.dig('address', 'locality')&.squish.presence,
      address_postal_code: s.dig('address', 'postalCode')&.squish.presence,
      address_region: s.dig('address', 'region')&.squish.presence,
      data_source_url: "https://www.gasbuddy.com/station/#{s['id']}"
    }
    station[:md5_hash] = calc_md5_hash(station)
    station[:zip_searched] = zip
    station
  end

  def parse_price(zip, s, p)
    price = {
      zip_searched:             zip,
      station_id:               s['id'],
      is_pay_available:         s.dig("payStatus", "isPayAvailable"),
      fuel_type:                p['fuelProduct'].presence,
      pwgb_discount:            fuel_pwgb_discount(s['offers'].first, p['fuelProduct']),
      credit_price:             p.dig('credit', 'price'),
      price_credit_posted_time: p.dig('credit', 'postedTime').presence,
      cash_price:               p.dig('cash', 'price'),
      price_cash_posted_time:   p.dig('cash', 'postedTime').presence,
      data_source_url:          "https://www.gasbuddy.com/station/#{s['id']}"
    }
    price[:md5_hash] = calc_md5_hash(price)
    price
  end

  def parse_trends(zip, station_count, zip_trends)
    trends = {}
    trends[:zip_searched] = zip
    trends[:station_count] = station_count
    zip_trends.each do |t|
      if t['areaName'] == "United States"
        trends[:country] = t['areaName']
        trends[:country_today] = t['today']
        trends[:country_today_low] = t['todayLow']
        trends[:country_trend] = t['trend']
      elsif US_STATE.include? t['areaName']
        trends[:state] = t['areaName']
        trends[:state_today] = t['today']
        trends[:state_today_low] = t['todayLow']
        trends[:state_trend] = t['trend']
      elsif t['areaName'] != 'Canada'
        trends[:area] = t['areaName']
        trends[:area_today] = t['today']
        trends[:area_today_low] = t['todayLow']
        trends[:area_trend] = t['trend']
      end
    end
    trends[:data_source_url] = "https://www.gasbuddy.com/home?search=#{zip}"
    trends[:md5_hash] = calc_md5_hash(trends)
    trends
  end

  def calc_md5_hash(hash)
    Digest::MD5.hexdigest hash.values.join
  end

  private

  def fuel_pwgb_discount(offer, fuel_type)
    offer['discounts'].each do |d|
      return d['pwgbDiscount'] if d['grades'].include? fuel_type
    end
  end

end
