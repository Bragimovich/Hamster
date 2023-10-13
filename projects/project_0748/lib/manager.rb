require_relative '../lib/parser'
require_relative '../lib/keeper'
require_relative '../lib/scraper'
class Manager <  Hamster::Harvester
  def initialize
    super
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = @keeper.run_id
  end

  def download
    @two_captcha = TwoCaptcha.new(Storage.new.two_captcha['general'], timeout: 200, polling: 10)
    already_downloaded_files = peon.list(subfolder: "#{run_id}") rescue []
    last_file = already_downloaded_files.sort.last rescue nil
    last_alpha = (last_file.nil?) ? 'aa' : last_file.split('.')[0]
    range = ('aa'..'zz').to_a
    last_file_index = range.find_index(last_alpha)
    last_file_index = 0 if last_file_index.nil?
    range[last_file_index..-1].each do |combination|
      f_name = combination[0]
      l_name = combination[1]
      cookie = renew_cookie
      names_post_res = scraper.names_post_req(f_name, l_name, cookie)
      names_get_res = scraper.names_get_req(cookie)
      save_page(names_get_res, "#{combination}_outer_page", "#{run_id}/#{combination}")
      all_links = parser.get_links(names_get_res.body)
      inner_pages_download(all_links, cookie, "#{combination}")
    end
  end

  def store
    scraper.mechanize_con
    @aws_s3 = AwsS3.new(bucket_key = :hamster, account=:hamster)
    all_doc_ids = keeper.fetch_doc_ids
    all_folders = peon.list(subfolder: "#{run_id}").sort rescue []
    all_folders.each do |inner_folder|
      getting_outerpage = "#{inner_folder}_outer_page.gz"
      content = peon.give(subfolder: "#{run_id}/#{inner_folder}", file: getting_outerpage)
      links = parser.get_links(content)
      links.each do |link|
        file_name = link.split('=')[1]
        inner_page = peon.give(subfolder: "#{run_id}/#{inner_folder}", file: file_name) rescue nil
        next if (inner_page.nil?) or (inner_page.include? 'Please enter the characters of the Captcha Text to continue') or (inner_page.include? 'An error has occurred during processing')
        document = parser.parse_page(inner_page)
        next if all_doc_ids.include? parser.get_doc_id(document)
        inmate_id = inmates_data(document)
        arrest_id = arrests_data(document, inmate_id)
        charge_id = charge_data(document, arrest_id)
        court_hearings_hash = missouri_court_hearings_fun(document, charge_id)
        inmate_ids_hash = missouri_inmate_ids_fun(document, inmate_id)
        inmate_addresses_hash = missouri_inmate_addresses_fun(document, inmate_id)
        holding_facilities_addresses_id = missouri_holding_facilities_addresses_fun(document)
        holding_facilities_hash = missouri_holding_facilities_fun(document, arrest_id, holding_facilities_addresses_id)
        mugshots_hash = missouri_mugshots_fun(document, link, inmate_id)
        inmate_additional_info_hash = missouri_inmate_additional_info_fun(document, inmate_id)
        inmate_aliases_hash = missouri_inmate_aliases_fun(document, inmate_id)
      end
    end
    keeper.marked_deleted
    keeper.finish
  end

  private
  attr_accessor :parser, :scraper, :keeper, :two_captcha, :run_id

  def inmates_data(document)
    missouri_inmates_hash = parser.missouri_inmates(document, run_id)
    keeper.insert_for_foreign_key(missouri_inmates_hash, 'missour_inmates')
  end


  def arrests_data(document, inmate_id)
    missouri_arrests_hash = parser.missouri_arrests(document, run_id, inmate_id)
    keeper.insert_for_foreign_key(missouri_arrests_hash,  'missouri_arrests')
  end

  def charge_data(document, arrest_id)
    missouri_charges_hash = parser.missouri_charges(document, run_id, arrest_id)
    keeper.insert_for_foreign_key(missouri_charges_hash, 'missouri_charges')
  end

  def missouri_court_hearings_fun(document, charge_id)
    missouri_court_hearings_hash = parser.missouri_court_hearings(document, run_id, charge_id)
    keeper.insert_data(missouri_court_hearings_hash, 'missouri_court_hearings')
  end

  def missouri_inmate_ids_fun(document, inmate_id)
    missouri_inmate_ids_hash = parser.missouri_inmate_ids(document, run_id, inmate_id)
    keeper.insert_data(missouri_inmate_ids_hash, 'missouri_inmate_ids')
  end

  def missouri_inmate_addresses_fun(document, inmate_id)
    missouri_inmate_addresses_hash = parser.missouri_inmate_addresses(document, run_id, inmate_id)
    keeper.insert_data(missouri_inmate_addresses_hash, 'missouri_inmate_addresses')
  end

  def missouri_holding_facilities_addresses_fun(document)
    missouri_holding_facilities_addresses_hash = parser.missouri_holding_facilities_addresses(document, run_id)
    keeper.insert_for_foreign_key(missouri_holding_facilities_addresses_hash,  'missouri_holding_facilities_addresses')
  end

  def missouri_holding_facilities_fun(document, arrest_id, holding_facilities_addresses_id)
    missouri_holding_facilities_hash = parser.missouri_holding_facilities(document, run_id, arrest_id, holding_facilities_addresses_id)
    keeper.insert_data(missouri_holding_facilities_hash, 'missouri_holding_facilities')
  end

  def missouri_mugshots_fun(document, link, inmate_id)
    image_url = parser.mugshot_link(document)
    aws_link = store_to_aws(image_url)
    missouri_mugshots_hash = parser.missouri_mugshots(document, link, run_id, inmate_id, aws_link)
    keeper.insert_data(missouri_mugshots_hash, 'missouri_mugshots')
  end

  def missouri_inmate_additional_info_fun(document, inmate_id)
    missouri_inmate_additional_info_array = parser.missouri_inmate_additional_info(document, run_id, inmate_id)
    keeper.insert_data(missouri_inmate_additional_info_array, 'missouri_inmate_additional_info')
  end

  def missouri_inmate_aliases_fun(document, inmate_id)
    missouri_inmate_aliases_array = parser.missouri_inmate_aliases(document, run_id, inmate_id)
    keeper.insert_data(missouri_inmate_aliases_array, 'missouri_inmate_aliases') unless missouri_inmate_aliases_array.empty?
  end

  def captcha_handling(captcha_image_url, cookie_value)
    captcha_image_response = scraper.captcha_request(captcha_image_url, cookie_value)
    solve_captcha(captcha_image_response)
  end

  def store_to_aws(link)
    body = scraper.fetch_image(link)
    key = Digest::MD5.new.hexdigest(link)
    @aws_s3.put_file(body, "crimes_mugshots/AR/#{key}.jpg")
  end

  def solve_captcha(captcha_image_response, retries = 5)
    begin
      solution = ''
      (1..5).map{
        solution = two_captcha.decode(raw: captcha_image_response.body)
        break if solution.api_response.include? 'OK'
      }
      solution
    rescue StandardError => e
      raise if retries <= 1
      solve_captcha(captcha_image_response, retries - 1)
    end
  end

  def renew_cookie
    main_page_response = scraper.main_page
    cookie = main_page_response.headers['set-cookie']
    captcha_image_url = parser.captcha_image_url(main_page_response)
    captcha_text = captcha_handling(captcha_image_url, cookie).text.strip
    welcome_post_res = scraper.welcome_post_req(captcha_text, cookie)
    cookie
  end

  def inner_pages_download(links, cookie, f_l_name)
    already_downloaded_files = peon.give_list(subfolder: "#{run_id}/#{f_l_name}")
    links.each do |link|
      file_name = link.split('=').last
      next if already_downloaded_files.include? "#{file_name}.gz"
      inner_link_page_html = scraper.get_inner_link_page(link, cookie)
      if inner_link_page_html.status == 302 or inner_link_page_html.body.include? 'Please enter the characters of the Captcha Text to continue'
        download
      end
      next if inner_link_page_html.body.empty?
      save_page(inner_link_page_html, file_name, "#{run_id}/#{f_l_name}")
    end
  end

  def save_page(html, file_name, sub_folder)
    peon.put(content: html.body, file: file_name, subfolder: sub_folder)
  end

end
