# frozen_string_literal: true

def connect_to_db
  Mysql2::Client.new(Storage[host: :db01, db: :usa_raw].except(:adapter).merge(symbolize_keys: true))
end

class Scraper < Hamster::Scraper

  def initialize(update=0)
    super
    client = connect_to_db
    run_id_class = RunId.new(client)
    @run_id = run_id_class.run_id
    if update==0
      scrape
    else
      scrape_weekly
      File.open("#{storehouse}/continue_update", 'w') { |file| file.write("Appraisers:1:") }
      deleted_for_not_equal_run_id(@run_id)
      deleted_for_not_equal_run_id_broker(@run_id)
    end
    run_id_class.update_column_status
  end

  def scrape_weekly
    licence_types = ["Appraisers", "Real+Estate", "Inspectors", "ERW", "AMC", "Providers"]

    n=0
    continue_line=licence_types[0]
    page_start=0
    if File.exist? "#{storehouse}/continue_update"
      File.open("#{storehouse}/continue_update", 'r') { |file| continue_line=file.read.split(":")}
      page_start = continue_line[1].to_i
      n = licence_types.index(continue_line[0])
      n=0 if n.nil?
    end


    licence_types[n..].each do |licence_type|
      existing_broker_links = []
      @filename = "#{storehouse}/sponsors_link_#{licence_type}"
      File.open(@filename, 'r') { |file| file.read.split("\n").each {|f| existing_broker_links.push(f)}} if File.exist? @filename
      ws = 370
      if page_start==0 or page_start.nil?
        page = 1
      else
        page=page_start
        page_start=0
      end

      loop do
        url = "https://www.trec.texas.gov/apps/license-holder-search/?lic_name=&industry=#{licence_type}&email=&city=&county=&zip=&display_status=&lic_hp=&ws=#{ws}&license_search=Search&showpage=#{page}"
        p url
        response = connect_to(url)
        if response.status>399
          ws+=25
          redo
        end
        html_page = response.body

        license_array, last_page = parse_main_page(html_page)

        lic_ids = license_array.map {|lic| lic[:license_number]}
        existing_lic_ids = get_existing_license_number(lic_ids)

        lic_ids_without_changing = []
        broker_links = Array.new()


        license_array.each do |lic|
          lic[:md5_hash] = make_md5(lic, :holder)
          if !lic[:license_number].to_i.in?(existing_lic_ids) || !exist_md5_hash(lic[:md5_hash])

            put_delete_for_lic(lic[:license_number]) if !exist_md5_hash(lic[:md5_hash]) && lic[:license_number].to_i.in?(existing_lic_ids)
            lic[:run_id] = @run_id
            put_holders(lic)
            holder_id = get_holder_id_by_lic_id(lic[:license_number])
            lic[:alternate_name].each {|alternate_name| put_alternate_names(holder_id, alternate_name)} if lic[:alternate_name]
          else
            lic_ids_without_changing.push(lic[:license_number].to_i)
          end

          broker_links.push(lic[:link])
        end
        put_run_id_lic_ids(@run_id, lic_ids_without_changing)

        existing_broker_links_db = existing_broker_links_expiration_date(broker_links)
        put_run_id_broker_links(@run_id, existing_broker_links_db)
        existing_broker_links += existing_broker_links_db

        broker_md5_hash = get_md5_broker(broker_links)

        broker_links.each do |link|
          next if link.in?(existing_broker_links)

          get_broker_weekly(link, broker_md5_hash)
          existing_broker_links.push(link)
        end

        existing_broker_links = existing_broker_links - existing_broker_links_db

        break if last_page==1
        page+=1
        File.open("#{storehouse}/continue_update", 'w') { |file| file.write("#{licence_type}:#{page}:") }
      end
    end
  end


  def scrape
    licence_types = ["Appraisers", "Real+Estate", "Inspectors", "ERW", "AMC", "Providers"]
    n=0
    continue_line=licence_types[0]
    page_start=0
    if File.exist? "#{storehouse}/continue"
      File.open("#{storehouse}/continue", 'r') { |file| continue_line=file.read.split(":")}
      page_start = continue_line[1].to_i
      n = licence_types.index(continue_line[0])
      n=0 if n.nil?
    end

    licence_types[n..].each do |licence_type|
      existing_broker_links = []
      @filename = "#{storehouse}/sponsors_link_#{licence_type}"
      File.open(@filename, 'r') { |file| file.read.split("\n").each {|f| existing_broker_links.push(f)}} if File.exist? @filename
      ws = 370
      if page_start==0 or page_start.nil?
        page = 1
      else
        page=page_start
        page_start=0
      end
      loop do
        url = "https://www.trec.texas.gov/apps/license-holder-search/?lic_name=&industry=#{licence_type}&email=&city=&county=&zip=&display_status=&lic_hp=&ws=#{ws}&license_search=Search&showpage=#{page}"
        p url
        response = connect_to(url)
        if response.status>399
          ws+=25
          redo
        end
        html_page = response.body

        license_array, last_page = parse_main_page(html_page)

        lic_ids = license_array.map {|lic| lic[:license_number]}
        existing_lic_ids = get_existing_license_number(lic_ids)
        broker_links = Array.new()

        license_array.each do |lic|
          if !lic[:license_number].to_i.in?(existing_lic_ids)
            lic[:md5_hash] = make_md5(lic, :holder)
            lic[:run_id] = @run_id
            put_holders(lic)
            holder_id = get_holder_id_by_lic_id(lic[:license_number])
            lic[:alternate_name].each {|alternate_name| put_alternate_names(holder_id, alternate_name)} if lic[:alternate_name]
          end
          broker_links.push(lic[:link])
        end



        existing_broker_links_db = get_existing_broker_links(broker_links)
        existing_broker_links += existing_broker_links_db


        broker_links.each do |link|
          next if link.in?(existing_broker_links)
          get_broker(link)
          existing_broker_links.push(link)
        end

        existing_broker_links = existing_broker_links - existing_broker_links_db
        break if last_page==1
        page+=1
        File.open("#{storehouse}/continue", 'w') { |file| file.write("#{licence_type}:#{page}:") }
      end

    end
  end


  def get_broker_weekly(link, broker_md5_hash)
    error_n=0

    begin
      html_broker_page = connect_to(link).body
    rescue
      error_n+=1
      raise "Bad connection to #{link}" if error_n>5
      sleep(1+error_n)
      retry
    end

    sponsors = parse_broker_page(html_broker_page, update=1)

    File.open(@filename, 'a') { |file| file.write("#{link}\n") } if sponsors.empty?
    exist_sponsors_link= []
    sponsors.each do |sponsor|
      sponsor = put_additional_info_to_sponsor(sponsor)
      sponsor[:link] = link

      if !sponsor[:md5_hash].in?(broker_md5_hash)
        put_sponsors(sponsor)
      else
        exist_sponsors_link.push(sponsor[:link])
      end
    end
    put_run_id_broker_links(@run_id, exist_sponsors_link)
  end


  def get_broker(link)
    error_n=0

    begin
      html_broker_page = connect_to(link).body
    rescue
      error_n+=1
      raise "Bad connection to #{link}" if error_n>5
      sleep(1+error_n)
      retry
    end

    sponsors = parse_broker_page(html_broker_page)

    File.open(@filename, 'a') { |file| file.write("#{link}\n") } if sponsors.empty?
    sponsors.each do |sponsor|
      sponsor = put_additional_info_to_sponsor(sponsor)
      sponsor[:link] = link
      sponsor[:run_id]=@run_id
      put_sponsors(sponsor)
    end
  end


  def put_additional_info_to_sponsor(sponsor)
    holder_info = get_holder_info_by_lic_id(sponsor[:holder_lic_number])
    sponsor[:holder_id] = holder_info[:id]
    sponsor[:sponsor_date] = DateTime.strptime(sponsor[:sponsor_date], "%m/%d/%Y") if sponsor[:sponsor_date] && sponsor[:sponsor_date]!=""
    sponsor[:expiration_date] = DateTime.strptime(sponsor[:expiration_date], "%m/%d/%Y") if sponsor[:expiration_date] && sponsor[:expiration_date]!=""
    sponsor[:md5_hash] =make_md5(sponsor, :sponsor)
    sponsor
  end

  COLUMNS = {
    holder: %i[holder_name license_number license_type license_link status expiration_date],
    sponsor: %i[role name holder_id sponsor_date license_number license_type sponsor_link expiration_date]
  }

  def make_md5(data_hash, type)
    all_values_str = ''
    columns = COLUMNS[type]
    columns.each do |key|
      if data_hash[key].nil?
        all_values_str = all_values_str + data_hash[key.to_s].to_s
      else
        all_values_str = all_values_str + data_hash[key].to_s
      end
    end
    Digest::MD5.hexdigest all_values_str
  end
end