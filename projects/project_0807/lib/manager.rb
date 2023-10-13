# frozen_string_literal: true

require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'

class Manager < Hamster::Harvester

  def initialize()
    super
    @keeper = Keeper.new
    @parser = Parser.new
    @scraper = Scraper.new
    @run_id = keeper.run_id.to_s
    @aws_s3 = AwsS3.new(bucket_key = :hamster, account = :hamster)
  end

  attr_accessor :keeper, :parser, :scraper, :run_id, :aws_s3

  def run
    keeper.download_status == 'finish' ? store : download
  end

  def download
    resume_counter = resume
    response = scraper.search_main_page
    page   = parser.parse_html(response.body)
    cookie = response.headers["set-cookie"]
    gen_values  = parser.get_body_data(page)
    response = scraper.search_results_page(gen_values, cookie)
    counter, response = (resume_counter != 1) ? skip_pages(resume_counter, response, cookie) : [1, response]
    loop do
      pp, paginated_gen_values = fetch_page_parms(response)
      links = parser.get_links(pp)
      process_links(links, cookie, paginated_gen_values, counter)
      counter += 1
      pages, next_flag = parser.get_pages(pp, counter)
      break if next_flag
      response = scraper.search_pagination(paginated_gen_values, cookie, counter.to_s)
    end
    keeper.finish_download
    store
  end

  def store
    inmates_md5, inmate_ids_md5, charges_md5, arrests_md5, mugshots_md5, addiotioanl_id_md5, aliases_md5 = [], [], [], [], [], [], []
    all_pages = peon.list(subfolder: "#{run_id}/").map{|f| f.to_i}.sort rescue []
    all_pages.each do |page|
      all_files = peon.list(subfolder: "#{run_id}/#{page}").reject{|f| f.include? "image"}.sort! rescue []
      all_files.each do |file|
        file_content = peon.give(subfolder: "#{run_id}/#{page}", file: file) rescue nil
        parsed_page  = parser.parse_html(file_content)
        inmates_hash    = parser.get_inmates_data(parsed_page, run_id)
        inmate_id = keeper.insert_record("inmate", inmates_hash)
        inmates_md5 << give_md5(inmates_hash)
        inmate_aliases_hash = parser.get_inmate_aliases(inmates_hash, inmate_id, run_id)
        aliases_md5 << give_md5(inmate_aliases_hash)
        keeper.insert_record("aliases", inmate_aliases_hash)
        inmates_id_hash = parser.get_inmates_id_data(parsed_page, run_id, inmate_id)
        inmate_ids_md5 << give_md5(inmates_id_hash)
        inmate_ids_id = keeper.insert_record("inmate_id", inmates_id_hash)
        inmate_ids_additional_array = parser.get_inmates_id_additional(parsed_page, inmate_ids_id, run_id)
        addiotioanl_id_md5 << give_md5(inmate_ids_additional_array[0])
        addiotioanl_id_md5 << give_md5(inmate_ids_additional_array[1])
        keeper.insert_multiple("addiotional_ids", inmate_ids_additional_array)
        arrests_hash    = parser.get_arrests_data(run_id, inmate_id)
        arrests_md5 << give_md5(arrests_hash)
        arrest_id       = keeper.insert_record("arrests", arrests_hash)
        charges_hash    = parser.get_charges_data(parsed_page, run_id, arrest_id)
        charges_md5 << give_md5(charges_hash)
        keeper.insert_record("charges", charges_hash)
        aws_link = upload_to_aws(file, page)
        mugshots_hash   = parser.get_mugshots_data(run_id, inmate_id, aws_link)
        mugshots_md5 << give_md5(mugshots_hash)
        keeper.insert_record("mugshots", mugshots_hash)
      end
    end
    md5_data_hashes = return_md5_hash(inmates_md5, inmate_ids_md5, arrests_md5, charges_md5, mugshots_md5, aliases_md5, addiotioanl_id_md5)
    if keeper.download_status == "finish"
      md5_data_hashes.each do |key, value|
        keeper.update_touch_run_id(key, value)
        keeper.delete_using_touch_id(key)
      end
      keeper.finish
    end
  end

  private

  def skip_pages(resume_counter, response, cookie)
    counter = 1
    while counter < resume_counter
      counter += 1
      pp, paginated_gen_values = fetch_page_parms(response)
      response   = scraper.search_pagination(paginated_gen_values, cookie, counter.to_s)
    end
    [counter, response]
  end

  def fetch_page_parms(response)
    pp = parser.parse_html(response.body)
    paginated_gen_values  = parser.get_body_data(pp)
    [pp, paginated_gen_values]
  end

  def return_md5_hash(inmates_md5, inmate_ids_md5, arrests_md5, charges_md5, mugshots_md5, aliases_md5, addiotioanl_id_md5)
    {
      "inmate"          => inmates_md5,
      "inmate_id"       => inmate_ids_md5,
      "arrests"         => arrests_md5,
      "charges"         => charges_md5,
      "mugshots"        => mugshots_md5,
      "aliases"         => aliases_md5,
      "addiotional_ids" => addiotioanl_id_md5
    }
  end

  def upload_to_aws(file, page)
    image_path = file.gsub(".gz", "_image.gz")
    img_file   = peon.give(subfolder: "#{run_id}/#{page}", file: image_path) rescue nil
    return if img_file.nil?
    aws_file_name = Digest::MD5.hexdigest(file.gsub(".gz", ""))
    aws_s3.put_file(img_file, "crimes_mugshots/AR/#{aws_file_name}.jpg")
  end

  def give_md5(hash)
    hash[:md5_hash]
  end

  def process_links(links, cookie, gen_values, page)
    links.each do |link|
      inner_page_response, img_response   = scraper.search_inner_page(gen_values, cookie, link)
      parsed_inner_page     = parser.parse_html(inner_page_response.body)
      file_name             = parser.get_file_name(inner_page_response)
      save_file("#{run_id}/#{page}", inner_page_response.body, file_name)
      next if !img_response.body.include? "JFIF"
      save_file("#{run_id}/#{page}", img_response.body, "#{file_name}_image")
    end
  end

  def resume
    max_counter = peon.list(subfolder: "#{run_id}").map(&:to_i).sort.max rescue nil
    return 1 if max_counter.to_s.empty?
    max_counter
  end

  def save_file(sub_folder, body, file_name)
    peon.put(content: body, file: file_name, subfolder: sub_folder)
  end
end
