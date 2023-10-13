require_relative '../lib/keeper'
require_relative '../lib/project_parser'
require_relative '../lib/scraper'
require_relative '../lib/converter'
require_relative '../models/additional_info'
require_relative '../models/case_activities'
require_relative '../models/case_party'
require_relative '../models/case_pdfs_on_aws'
require_relative '../models/case_relations_info_pdf'
require_relative '../models/case_relations_activity_pdf'
require_relative '../models/case_info'
require_relative '../models/runs'

class Manager < Hamster::Harvester
  MAIN_URL = 'https://appellatecases.courtinfo.ca.gov'
  URL = 'https://appellatecases.courtinfo.ca.gov/search/'
  DIST_PATH = 'searchResults.cfm?dist='
  AWS_URL = 'https://court-cases-activities.s3.amazonaws.com/'
  HEADERS = {
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:98.0) Gecko/20100101 Firefox/98.0',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3',
    'Accept-Encoding': 'gzip, deflate, br',
    'Referer': 'https://appellatecases.courtinfo.ca.gov/search/searchResults.cfm?dist=0&search=party',
    'Proxy-Authorization': 'Basic bm9paHRwa206aDRrYnUwa241cnVv',
    'Connection': 'keep-alive',
    'Cookie': 'cfid=b64daab0-98cb-4ad1-92ce-0df8593179d2; cftoken=0; _ga=GA1.2.1840626845.1652717357; _gid=GA1.2.1873242982.1652717357',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'same-origin',
    'Sec-Fetch-User': '?1',
    'Pragma': 'no-cache',
    'Cache-Control': 'no-cache'
  }

  def initialize(**params)
    super
    @scraper_name = 'vyacheslav pospelov'
    @filter = ProxyFilter.new(duration: 3.hours, touches: 1000)
    @filter.ban_reason = proc { |response| ![200, 302, 304].include?(response.status) || response.body.size.zero? }
    @scraper = Scraper.new
    @scraper.safe_connection{
      @runs = RunId.new(Runs)
      @run_id = @runs.run_id
    }                                                                                                    
    @keeper_case_info = Keeper.new(CaseInfo, @run_id, @scraper_name,
                                   [{ rel_model: CaseRelationsInfoPdf, rel_keys: [:case_info_md5] }])
    @keeper_pdf_aws = Keeper.new(CasePdfsOnAws, @run_id, @scraper_name,
                                 [{ rel_model: CaseRelationsInfoPdf, rel_keys: [:case_pdf_on_aws_md5] }])
    @keeper_rel_pdf = Keeper.new(CaseRelationsInfoPdf, @run_id)
    @keeper_case_activty = Keeper.new(CaseActivities, @run_id)
    @keeper_case_party = Keeper.new(CaseParty, @run_id)
    @keeper_additional_info = Keeper.new(AdditionalInfo, @run_id)
    #fix_md5
    #fix_touched_run_id
    @parser = Project_Parser.new(@run_id)
    @converter = Converter.new(@run_id)
    @s3 = AwsS3.new(:us_court)
    @full_scrape = true
    # @scraper.safe_connection{ @runs.status = "processing a b 410 99" }
    # @scraper.safe_connection{ @runs.status = "processing z z 409 1" }
    # @scraper.safe_connection{ @runs.status = "processing a n 305 107" } #error fixed
    # @scraper.safe_connection{ @runs.status = "processing a o 305 19" } #error fixed
    # @scraper.safe_connection{ @runs.status = "processing j i 408 48" } # saved last status for 408 court
  end

  def fix_md5
    @keeper_case_info.fix_wrong_md5
    @keeper_pdf_aws.fix_wrong_md5
    @keeper_rel_pdf.fix_wrong_md5
    @keeper_case_activty.fix_wrong_md5
    @keeper_case_party.fix_wrong_md5
    @keeper_additional_info.fix_wrong_md5
  end

  def fix_touched_run_id
    @keeper_case_info.fix_empty_touched_run_id
    @keeper_pdf_aws.fix_empty_touched_run_id
    @keeper_rel_pdf.fix_empty_touched_run_id
    @keeper_case_activty.fix_empty_touched_run_id
    @keeper_case_party.fix_empty_touched_run_id
    @keeper_additional_info.fix_empty_touched_run_id
  end

  def download
    @parser.html = @scraper.body(url: "#{URL}#{DIST_PATH}", use: 'hammer')
    @appellate_links = @parser.appellate_links
    save_supreme_courts
    save_appellate_courts
    on_finish
  end

  def save_supreme_courts
    navigation("#{URL}#{DIST_PATH}0", 305, 'supreme')
  end

  def save_appellate_courts
    @appellate_links.each_with_index do |link, index|
      navigation(link, @parser.court_id_arr[index], 'appellate')
    end
  end

  def navigation(link, court_id, court_type)
    splited_status = @scraper.safe_connection{ @runs.status }.split(" ")
    first_navigation_char = splited_status[1]
    second_navigation_char = splited_status[2]
    navigation_court_id = splited_status[3]

    return if navigation_court_id && navigation_court_id != court_id.to_s

    navigation_court_id = court_id.to_s

    @full_scrape = false if first_navigation_char

    first_char_found = false
    second_char_found = false

    ('a'..'z').each do |first_char|
      first_char_found = true if first_char == first_navigation_char

      next if first_navigation_char && !first_char_found

      ('a'..'z').each do |second_char|
        second_char_found = true if second_char == second_navigation_char

        next if second_navigation_char && !second_char_found

        splited_status[1] = first_char
        splited_status[2] = second_char
        splited_status[3] = navigation_court_id
        old_courts = false

        # page_link = "#{link}&search=party&query_partyLastNameOrOrg=#{first_char}#{second_char}&start="
        page_link = "#{link}&search=attorney&query_attyLastName=#{first_char}#{second_char}&query_attyLawFirm=&start=="
        @parser.html = @scraper.body(url: page_link, use: 'connect_to', ssl_verify: false, proxy_filter: @filter)

        next if @parser.count_courts.blank?

        count_courts_on_page = 25
        help_index = 0
        (1...@parser.count_courts).step(count_courts_on_page).each do |num_page|
          old_courts = courts("#{page_link}#{num_page}", court_id, court_type, splited_status, help_index)

          break if old_courts

          help_index += 1
        end

        splited_status[4] = nil
        splited_status[2] = splited_status[2].next! if splited_status[2].next!.size == 1
        @scraper.safe_connection{ @runs.status = splited_status.join(" ") }
      end
    end
    splited_status[1] = "a"
    splited_status[2] = "a"
    splited_status[3] = nil
    splited_status[4] = nil
    @scraper.safe_connection{ @runs.status = splited_status.join(" ") }
  end

  def courts(page_link, court_id, court_type, splited_status, help_index)
    old_courts = false
    help_index = help_index * 25
    @parser.html = @scraper.body(url: page_link, use: 'connect_to', ssl_verify: false, proxy_filter: @filter)
    courts_links = @parser.courts_links

    return if courts_links.empty?

    iteration_index = splited_status[4]
    index_found = false

    courts_links.each_with_index do |temp_link, index|
      index_found = true if iteration_index == (help_index + index).to_s

      next if temp_link.nil?

      next if iteration_index && !index_found

      splited_status[4] = (help_index + index + 1).to_s
      @scraper.safe_connection{ @runs.status = splited_status.join(" ") }
      @scraper.connect_to_set_cookie(temp_link, proxy_filter: @filter, headers: HEADERS, ssl_verify: false)
      response = @scraper.response
      location = response&.headers["location"]

      return if response.nil? || location.nil?

      case_url = "#{URL}case/#{location}"
      @parser.html = @scraper.body(url: case_url, use: 'connect_to', ssl_verify: false, proxy_filter: @filter)
      menu_links = @parser.menu_links
      case_id, date = save_case_info(case_url, court_id, court_type)

      return old_courts = true if date < Time.parse("2016/1/1").strftime('%Y-%m-%d').to_s
      @parser.menu_names.each_with_index do |name, index|
        case name
        when 'Docket'
          @docket_link = menu_links[index]
          save_case_activities(@docket_link, case_id, court_id)
        when 'Parties and Attorneys'
          @part_att_link = menu_links[index]
          save_case_party(@part_att_link, case_id, court_id)
        when 'Lower Court'
          @lower_court_link = menu_links[index]
          save_additional_info(@lower_court_link, case_id, court_id)
        end
      end
    end
    old_courts
  end

  def save_pdf(pdf_link, court_id, case_id, md5_info)
    unless pdf_link.nil?
      file_name = pdf_link.split('/').last
      key = "us_courts_expansion_#{court_id}_#{case_id}_#{file_name}"
      content = @scraper.body(use: 'get_pdf', url: pdf_link, file_name: file_name.to_s)
      if content.nil?
        @scraper.safe_connection{
          Hamster.report(
            to: @scraper_name,
            message: "project-#{Hamster::project_number} \n wrong pdf link= #{pdf_link} ",
            use: :both
          )
        }
        return
      end
      upload_file_to_aws(content, key, pdf_link)
      pdf_data = {
        aws_link: "#{AWS_URL}#{key}",
        court_id: court_id,
        case_id: case_id,
        source_type: 'info',
        source_link: pdf_link,
      }
      md5_pdf_on_aws = @converter.to_md5(pdf_data)
      pdf_data.merge!(md5_hash: md5_pdf_on_aws)
      @keeper_pdf_aws.upsert_all(pdf_data)
      rel_data = {
        court_id: court_id,
        case_info_md5: md5_info,
        case_pdf_on_aws_md5: md5_pdf_on_aws
      }
      @keeper_rel_pdf.upsert_all(rel_data)
    end
  end

  # Case Summary
  def save_case_info(link, court_id, court_type)
    @parser.html = @scraper.body(url: link, use: 'connect_to', ssl_verify: false, proxy_filter: @filter)
    save_file(@parser.html, "_case_info_#{@converter.to_md5(@parser.html)}.html")
    data = @parser.case_info(link, court_id, court_type)
    data = @converter.clean_data(data)

    return unless data[:case_id]

    @keeper_case_info.update_deleted_by_column(:case_id, data[:case_id])
    data = @keeper_case_info.upsert_all(data).first
    save_pdf(@parser.pdf_link, court_id, data[:case_id], data[:md5_hash])
    [data[:case_id], data[:case_filed_date]]
  end

  def save_case_activities(link, case_id, court_id)
    @parser.html = @scraper.body(url: link, use: 'connect_to', ssl_verify: false, proxy_filter: @filter)
    save_file(@parser.html, "_case_activities_#{@converter.to_md5(@parser.html)}.html")
    @keeper_case_activty.upsert_all(@parser.case_activities(link, case_id, court_id))
  end

  # Parties and Attorneys
  def save_case_party(link, case_id, court_id)
    @parser.html = @scraper.body(url: link, use: 'connect_to', ssl_verify: false, proxy_filter: @filter)
    save_file(@parser.html, "_case_party_#{@converter.to_md5(@parser.html)}.html")
    @keeper_case_party.upsert_all(@parser.case_party(link, case_id, court_id))
  end

  # Lower Court
  def save_additional_info(link, case_id, court_id)
    @parser.html = @scraper.body(url: link, use: 'connect_to', ssl_verify: false, proxy_filter: @filter)
    save_file(@parser.html, "_additional_info_#{@converter.to_md5(@parser.html)}.html")
    @keeper_additional_info.upsert_all(@parser.additional_info(link, case_id, court_id))
  end

  def upload_file_to_aws(content, key, source_link)
    @s3.put_file(content, key, metadata={url: source_link})
  end

  def save_file(html, filename, subfolder = nil)
    data = {
      content: html.to_s,
      file: filename
    }
    data.merge!(subfolder: subfolder) if subfolder
    peon.put(data) unless html.blank?
  end

  def create_tar
    path = "#{storehouse}store"
    time = Time.parse(Time.now.to_s).strftime('%Y-%m-%d').to_s
    file_name = @run_id ? "#{path}/#{time}_#{@run_id}.tar" : "#{path}/#{time}.tar"
    File.open(file_name, 'wb') { |tar| Minitar.pack(Dir.glob("#{path}"), tar) }
    move_folder("#{path}/*.tar", "#{storehouse}trash")
    clean_dir(path)
    file_name
  end

  def clean_dir(path)
    FileUtils.rm_rf("#{path}/.", secure: true)
  end

  def move_file(file_path, path_to)
    FileUtils.mv(file_path, path_to)
  end

  def move_folder(folder_path, path_to)
    FileUtils.mv(Dir.glob("#{folder_path}"), path_to)
  end

  def directory_size(path)
    require 'find'
    size = 0
    Find.find(path) do |f| size += File.stat(f).size end
    size
  end

  def tars_to_aws
    s3 = AwsS3.new(:hamster,:hamster)
    create_tar
    path = "#{storehouse}trash"
    if (directory_size("#{path}").to_f / 1000000).round(2) > 1000 # Mb
      Dir.glob("#{path}/*.tar").each do |tar_path|
        content = IO.read(tar_path)
        key = tar_path.split('/').last
        s3.put_file(content, "tasks/scrape_tasks/st0#{Hamster::project_number}/#{key}", metadata = {})
      end
      clean_dir(path)
    end
  end

  def on_finish
    @keeper_case_info.update_deleted
    @keeper_case_activty.update_deleted
    @keeper_case_party.update_deleted
    @keeper_additional_info.update_deleted
    @scraper.safe_connection{ @runs.finish }
    tars_to_aws
  end
end