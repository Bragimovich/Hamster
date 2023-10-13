# frozen_string_literal: true

require_relative 'keeper'
require_relative 'parser'
require_relative 'scraper'

require 'uri'

class Manager < Hamster::Scraper
  def initialize(options)
    super

    upload_aws_proc =
      Proc.new do |model_name, record_hash, file_key|
        upload_file_to_aws(model_name, record_hash, file_key)
      end

    @options = options
    @scraper = Scraper.new
    @parser  = Parser.new
    @aws_s3  = AwsS3.new(:hamster, :hamster)

    @keeper = Keeper.new(
      max_buffer_size: @options[:buffer],
      run_model:       'CtHartfoldInmateRun',
      upload_aws_cb:   upload_aws_proc
    )
  end

  def run
    sa_configs = {}

    ('a'..'z').each do |letter|
      @scraper.reset_site_cookies

      payload = {
        'id_inmt_num'   => '',
        'nm_inmt_last'  => letter,
        'nm_inmt_first' => '',
        'dt_inmt_birth' => '',
        'submit1'       => 'Search All Inmates'
      }

      list_html = @scraper.post_payload('http://www.ctinmateinfo.state.ct.us/resultsupv.asp', payload)
      list_data = @parser.parse_inmate_list(list_html)
      list_data.each do |inmate|
        inmate_url  = "http://www.ctinmateinfo.state.ct.us/detailsupv.asp?id_inmt_num=#{inmate[:inmate_number]}"
        inmate_html = @scraper.get_site_content(inmate_url, bypass_codes: [500])
        next if inmate_html.nil?

        inmate = inmate.merge(@parser.parse_inmate_details(inmate_html))
        site_id, agency_id = @parser.parse_site_agency(inmate_html)
        sa_key = "#{site_id}_#{agency_id}"
        sa_cfg = sa_configs[sa_key]

        if sa_cfg.nil?
          cfg_url  = "https://vinelink-mobile.vineapps.com/api/v1/legacySites/#{site_id}/legacyAgencies/#{agency_id}"
          cfg_json = @scraper.get_api_content(cfg_url)
          sa_cfg   = @parser.parse_site_agency_json(cfg_json)
          sa_configs[sa_key] = sa_cfg
        end

        vine_url  = "https://vinelink-mobile.vineapps.com/api/v1/guest/persons?limit=20&offset=0&showPhotos=false&isPartialSearch=false&personContextRefId=#{inmate[:inmate_number]}&siteRefId=#{sa_cfg[:site_ref]}&agencyRefId=#{sa_cfg[:agency_ref]}&sortByDeleteDateAndLastUpdatedDate=false&includeJuveniles=false&includeSearchBlocked=false&includeRegistrantInfo=true&addImageWatermark=true&personContextTypes=OFFENDER&obscurePersonData=true"
        vine_json = @scraper.get_api_content(vine_url, bypass_codes: [500])
        inmate = inmate.merge(@parser.parse_vine_json(vine_json)) unless vine_json.nil?

        photo_uri  = URI.parse(inmate[:photo_link]) rescue nil
        photo_path =
          if photo_uri.nil?
            nil
          else
            photo_uri.query = nil
            photo_uri.to_s
          end
        inmate[:photo_path] = photo_path

        save_records(inmate, inmate_url)
      end
    end

    @keeper.flush
    @keeper.mark_deleted
    @keeper.finish
  rescue Exception => e
    cause_exc = e.cause || e
    unless cause_exc.is_a?(::Mysql2::Error) || cause_exc.is_a?(::ActiveRecord::ActiveRecordError)
      @keeper.flush rescue nil
    end
    raise e
  end

  private

  def build_address_plain(inmate)
    build_plain_value(inmate, %i[fac_full fac_addr fac_city fac_state fac_zip])
  end

  def build_arrest_plain(inmate)
    build_plain_value(inmate, %i[status booking_date booking_agency])
  end

  def build_inmate_plain(inmate)
    build_plain_value(inmate, %i[full_name first_name middle_name last_name birthdate])
  end

  def build_plain_value(inmate, keys)
    keys.map { |key| inmate[key].to_s }.join
  end

  def save_records(inmate, data_source_url)
    inmate_plain  = build_inmate_plain(inmate)
    arrest_plain  = build_arrest_plain(inmate)
    address_plain = build_address_plain(inmate)

    # inmate
    base_data = {
      birthdate:   inmate[:birthdate],
      first_name:  inmate[:first_name],
      full_name:   inmate[:full_name],
      last_name:   inmate[:last_name],
      middle_name: inmate[:middle_name]
    }

    if base_data.compact.present?
      @keeper.save_data(
        'CtHartfoldInmate',
        { data_source_url: data_source_url }.merge(base_data)
      )
    end

    # inmate_id
    base_data = { inmate_number: inmate[:inmate_number] }
    if inmate_plain.present? && base_data.compact.present?
      @keeper.save_data(
        'CtHartfoldInmateId',
        { data_source_url: data_source_url, inmate_plain: inmate_plain }.merge(base_data)
      )
    end

    # arrest
    base_data = {
      booking_agency: inmate[:booking_agency],
      booking_date:   inmate[:booking_date],
      status:         inmate[:status]
    }

    if inmate_plain.present? && base_data.compact.present?
      @keeper.save_data(
        'CtHartfoldArrest',
        { data_source_url: data_source_url, inmate_plain: inmate_plain }.merge(base_data)
      )
    end

    # bond
    base_data = { bond_amount: inmate[:bond_amount] }
    if inmate_plain.present? && arrest_plain.present? && base_data.compact.present?
      @keeper.save_data(
        'CtHartfoldBond',
        {
          arrest_plain:    arrest_plain,
          data_source_url: data_source_url,
          inmate_plain:    inmate_plain
        }.merge(base_data)
      )
    end

    # facility_address
    base_data = {
      city:           inmate[:fac_city],
      full_address:   inmate[:fac_full],
      state:          inmate[:fac_state],
      street_address: inmate[:fac_addr],
      zip:            inmate[:fac_zip]
    }

    if base_data.compact.present?
      @keeper.save_data('CtHartfoldHoldingFacilitiesAddress', base_data)
    end

    # facility
    base_data = {
      facility:             inmate[:facility],
      max_release_date:     inmate[:max_release_date],
      planned_release_date: inmate[:planned_release_date]
    }

    if inmate_plain.present? && arrest_plain.present? && address_plain.present? && base_data.compact.present?
      @keeper.save_data(
        'CtHartfoldHoldingFacility',
        {
          address_plain:   address_plain,
          arrest_plain:    arrest_plain,
          data_source_url: data_source_url,
          inmate_plain:    inmate_plain
        }.merge(base_data)
      )
    end

    # mugshot
    base_data = { original_link: inmate[:photo_path], original_link_dl: inmate[:photo_link] }
    if inmate_plain.present? && base_data.compact.present?
      @keeper.save_data(
        'CtHartfoldMugshot',
        { data_source_url: data_source_url, inmate_plain: inmate_plain }.merge(base_data)
      )
    end

    # parole_booking
    base_data = { date: inmate[:parole_date] }
    if inmate_plain.present? && base_data.compact.present?
      @keeper.save_data(
        'CtHartfoldParoleBookingDate',
        { inmate_plain: inmate_plain }.merge(base_data)
      )
    end
  end

  def upload_file_to_aws(model_name, record_hash, file_key)
    return nil unless model_name == 'CtHartfoldMugshot' && file_key.to_s == 'original_link_dl'
    return nil if record_hash.nil? || record_hash[file_key].nil?

    dl_result =
      @scraper.get_api_content(
        record_hash[file_key],
        connector:    { keep_params: true },
        content_type: :image,
        bypass_codes: [401, 500, 404],
      )

    if dl_result.nil?
      nil
    else
      s3_path = "inmates/ct/hartfold/#{record_hash[:md5_hash]}.jpg"
      @aws_s3.put_file(dl_result, s3_path)
    end
  end
end
