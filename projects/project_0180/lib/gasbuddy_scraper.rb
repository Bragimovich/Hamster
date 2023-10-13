# frozen_string_literal: true

class GasBuddyScraper < Hamster::Scraper

  SOURCE = 'https://www.gasbuddy.com/'

  def initialize
    super
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 304].include?(response.status) || response.body.size.zero? }
  end

  def data_by_api(zip, cursor, timezone)
    post_to_graphql(zip, cursor, timezone)
  end

  def webpage_by_url(url_file)
    connect_to(url_file, proxy_filter: @filter, ssl_verify: false)&.body
  end

  private

  def post_to_graphql(zip, cursor, timezone)
    # old_query: "query LocationBySearchTerm($brandId: Int, $cursor: String, $fuel: Int, $lat: Float, $lng: Float, $maxAge: Int, $search: String) { locationBySearchTerm(lat: $lat, lng: $lng, search: $search) { countryCode displayName latitude longitude regionCode stations(brandId: $brandId, cursor: $cursor, fuel: $fuel, maxAge: $maxAge) { count cursor { next __typename } results { latitude longitude phone #{timezone} brand_name status address { country line1 line2 locality postalCode region __typename } badges { badgeId callToAction campaignId clickTrackingUrl description detailsImageUrl detailsImpressionTrackingUrls imageUrl impressionTrackingUrls targetUrl title __typename } brandings { brand_id branding_type __typename } brands { brand_id image_url name __typename } emergency_status { has_diesel { nick_name report_status update_date __typename } has_gas { nick_name report_status update_date __typename } has_power { nick_name report_status update_date __typename } __typename } enterprise fuels id name offers { discounts { grades highlight pwgbDiscount receiptDiscount __typename } highlight id types use __typename } pay_status { is_pay_available __typename } prices { cash { nickname posted_time price __typename } credit { nickname posted_time price __typename } discount fuel_product __typename } ratings_count star_rating __typename } __typename } trends { areaName today todayLow trend __typename } __typename } } "
    headers = { Content_Type: 'application/json' }
    link = 'https://www.gasbuddy.com/graphql'
    form_data = {
      variables: { maxAge: 0, search: zip, cursor: cursor },
      query: "query LocationBySearchTerm($brandId: Int, $cursor: String, $fuel: Int, $lat: Float, $lng: Float, $maxAge: Int, $search: String) { locationBySearchTerm(lat: $lat, lng: $lng, search: $search) { countryCode displayName latitude longitude regionCode stations(brandId: $brandId, cursor: $cursor, fuel: $fuel, maxAge: $maxAge) { count cursor { next __typename } results { latitude longitude phone #{timezone} brandName status address { country line1 line2 locality postalCode region __typename } badges { badgeId callToAction campaignId clickTrackingUrl description detailsImageUrl detailsImpressionTrackingUrls imageUrl impressionTrackingUrls targetUrl title __typename } brandings { brandId brandingType __typename } brands { brandId imageUrl name __typename } emergencyStatus { hasDiesel { nickname reportStatus updateDate __typename } hasGas { nickname reportStatus updateDate __typename } hasPower { nickname reportStatus updateDate __typename } __typename } enterprise fuels id name offers { discounts { grades highlight pwgbDiscount receiptDiscount __typename } highlight id types use __typename } payStatus { isPayAvailable __typename } prices { cash { nickname postedTime price formattedPrice __typename } credit { nickname postedTime price formattedPrice __typename } discount fuelProduct __typename } priceUnit ratingsCount starRating __typename } __typename } trends { areaName country today todayLow trend __typename } __typename } }"
    }.to_json

    response = connect_to(link,
                          proxy_filter: @filter,
                          ssl_verify: false,
                          method: :post,
                          req_body: form_data,
                          headers: headers,)&.body

    response
  rescue
    nil
  end

end

