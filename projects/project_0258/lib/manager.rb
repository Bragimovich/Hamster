# frozen_string_literal: true
require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager <  Hamster::Harvester

  def initialize
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
    s3 = get_aws_s3_client
    bucketname = Storage.new.buckets[:loki]
    @bucket = s3.bucket(bucketname)
  end

  def download
    outer_page_response = scraper.outer_page_request
    outerpage_cookie    = fetch_cookie(outer_page_response)
    inner_page_response = scraper.outer_page_request_two(outerpage_cookie)
    innerpage_cookie    = fetch_cookie(inner_page_response)
    main_page_response  = scraper.get_main_page(outerpage_cookie, innerpage_cookie)
    form_data_info      = parser.fetch_folder_info(main_page_response.body, "Fire Department Folder")
    main_page_cookie    = fetch_cookie(main_page_response)
    cookie_value        = "#{outerpage_cookie};  AcceptsCookies=1; #{innerpage_cookie.split(",")[0...-1].join(",")} , #{main_page_cookie}"
    response            = scraper.get_inner_folder(form_data_info, cookie_value)
    form_data_info      = parser.fetch_folder_info(response.body, "Fire Commission Folder")
    response            = scraper.get_inner_folder(form_data_info, cookie_value)
    form_data_info      = parser.fetch_folder_info(response.body, "Monthly Chief's Report Folder")
    response            = scraper.get_inner_folder(form_data_info, cookie_value)
    folders_info_array, form_data_info = parser.fetch_all_folders(response.body)
    folders_info_array[0].each do |folder_info|
      updated_form_data_info = form_data_info.clone
      updated_form_data_info.unshift(folder_info[:link])
      response = scraper.get_inner_folder(updated_form_data_info, cookie_value)
      if folder_info[:name] == "FY20-21"
        deal_with_pdfs_downloading(response.body, folder_info[:name])
      else
        inner_folders_info_array, inner_form_data_info = parser.fetch_all_folders(response.body)
        inner_folders_info_array[0].each do |inner_folder_info|
          updated_inner_form_data_info = inner_form_data_info.clone
          updated_inner_form_data_info.unshift(inner_folder_info[:link])
          response = scraper.get_inner_folder(updated_inner_form_data_info, cookie_value)
          deal_with_pdfs_downloading(response.body, inner_folder_info[:name])
        end
      end
    end
  end

  def store
    already_inserted_records = keeper.already_inserted_records
    pdfs_folders = peon.list.sort
    pdfs_folders.each do |sub_folder|
      puts "subfolder ===================   #{sub_folder}   ============="
      outer_page = peon.give(file: "outer_page", subfolder: sub_folder)
      data_array = parser.parse(outer_page, sub_folder, keeper.run_id)
      data_array.each do |record|
        next if already_inserted_records.include? record[:md5_hash]

        aws_url   = upload(record[:src_pdf_link], record[:src_pdf_link].split("/")[-2], sub_folder )
        record[:aws_pdf_link] = aws_url
        if record[:document_name].include? "ANNUAL"
          keeper.annual_insertion(record)
        else
          keeper.monthly_insertion(record)
        end
      end
    end
    keeper.mark_deleted
    keeper.finish
  end

  private

  attr_accessor :keeper, :parser, :scraper

  def fetch_cookie(response)
    response.headers["set-cookie"]
  end

  def deal_with_pdfs_downloading(html, folder_name)
    pdfs_links = parser.fetch_pdf_links(html)
    return if pdfs_links.empty?

    pdfs_links.each do |id|
      response = scraper.get_pdf(id)
      name = id + ".pdf"
      save_file(response.body, name, folder_name.gsub("-", "_"))
    end
    save_file(html, "outer_page", folder_name.gsub("-", "_"))
  end

  def get_aws_s3_client
    aws_keys = Storage.new.aws_credentials_loki
    Aws.config.update(
      access_key_id: (aws_keys['access_key_id']).to_s,
      secret_access_key: (aws_keys['secret_access_key']).to_s,
      region: 'us-east-1'
    )
    Aws::S3::Resource.new(region: 'us-east-1')
  end

  def upload(pdf_url, pdf_name, sub_folder)
    content = peon.give(file: "#{pdf_name}.pdf.gz", subfolder: sub_folder)
    url = @bucket.put_object(
      acl: 'public-read',
      key: pdf_url,
      body: content,
      metadata: {}
    ).public_url
  end

  def save_file(html, file_name, sub_folder)
    peon.put content: html, file: file_name, subfolder: sub_folder
  end
end
