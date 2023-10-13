require_relative '../lib/keeper'
require_relative '../lib/project_parser'
require_relative '../lib/scraper'
require_relative '../lib/converter'
require_relative '../models/additional_info'
require_relative '../models/case_activities'
require_relative '../models/case_party'
require_relative '../models/case_pdfs_on_aws'
require_relative '../models/case_relations_activity_pdf'
require_relative '../models/case_info'
require_relative '../models/runs'

class Manager < Hamster::Harvester
  SOURCE = 'https://ctrack.sccourts.org/public/caseSearch.do'
  SUB_PATH = '/news/releases?search_api_fulltext=&sort_bef_combine=published_at_DESC&sort_by=published_at&sort_order=DESC&page='
  HEADERS = {
    accept:                    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
    accept_encoding:           'utf-8',
    accept_language:           'en-GB,en-US;q=0.9,en;q=0.8',
    cache_control:             'max-age=0',
    sec_fetch_dest:            'document',
    sec_fetch_mode:            'navigate',
    sec_fetch_site:            'none',
    sec_fetch_user:            '?1',
    upgrade_insecure_requests: '1',
    "User-Agent" => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36'
  }

  def initialize(**params)
    super
    #@keeper_test = Keeper.new(CaseInfo)
    @scraper_name = 'vyacheslav pospelov'
    @runs = RunId.new(Runs)
    @run_id = @runs.run_id
    @keeper_case_info = Keeper.new(CaseInfo, @run_id, @scraper_name)
    @keeper_case_activty = Keeper.new(CaseActivities, @run_id, @scraper_name,
                                      [{ rel_model: CaseRelationsActivityPdf, rel_keys: [:case_activities_md5] }])
    @keeper_case_party = Keeper.new(CaseParty, @run_id, @scraper_name)
    @keeper_additional_info = Keeper.new(AdditionalInfo, @run_id, @scraper_name)
    @keeper_pdf_aws = Keeper.new(CasePdfsOnAws, @run_id, @scraper_name)
    @keeper_rel_activ_pdf = Keeper.new(CaseRelationsActivityPdf, @run_id, @scraper_name)
    fix_touched_run_id
    fix_md5
    @parser = Project_Parser.new(@run_id)
    @scraper = Scraper.new
    @converter = Converter.new(@run_id)
    @s3 = AwsS3.new(:us_court)
  end

  def fix_md5
    @keeper_case_info.fix_wrong_md5
    @keeper_pdf_aws.fix_wrong_md5
    @keeper_rel_activ_pdf.fix_wrong_md5
    @keeper_case_activty.fix_wrong_md5
    @keeper_case_party.fix_wrong_md5
    @keeper_additional_info.fix_wrong_md5
  end

  def fix_touched_run_id
    @keeper_case_info.fix_empty_touched_run_id
    @keeper_pdf_aws.fix_empty_touched_run_id
    @keeper_rel_activ_pdf.fix_empty_touched_run_id
    @keeper_case_activty.fix_empty_touched_run_id
    @keeper_case_party.fix_empty_touched_run_id
    @keeper_additional_info.fix_empty_touched_run_id
  end

  def download
    browser = @scraper.hammer_browser(
      url: SOURCE,
      sleep: 10,
      expected_css: "input[name=toDt]",
      headless: false
    )
    @parser.browser = browser
    save_htmls(browser)
    on_finish
  rescue => e
    Hamster.report(
      to: @scraper_name,
      message: "#{Hamster::PROJECT_DIR_NAME}_#{Hamster::project_number}--download: Error - \n#{e.full_message} ",
      use: :both
    )
    puts ['*'*77,  e.full_message]
  ensure
    @scraper.close_browser
  end

  def store # without case_activity and pdf links
    peon.give_list(subfolder: "html/court_info/").each do |file|
      @parser.html = peon.give(subfolder: "html/court_info/", file: file)
    end
  end

  def save_htmls(browser)
    browser.at_css('input[name=fromDt]').focus.type('01/01/2016')
    arr = Time.parse(Time.now.to_s).strftime('%Y-%m-%d').to_s.split("-") # 2022-09-12
    time_now = [arr[1], arr[2], arr[0]].join("/").to_s
    browser.at_css('input[name=toDt]').focus.type(time_now, :enter)

    all_links = []
    retries = 0
    begin
      expected_css = "table.FormTable tr.OddRow"
      @scraper.wait_css_with_refresh(expected_css, 15)

      raise "Waited css not found. Retry ##{retries}" if browser.at_css(expected_css).nil?

      save_file(browser.body, "#{@converter.to_md5(browser.body.to_s)}.html", "html/court_lists/")

      odd_links = @parser.absolute_url_list('table.FormTable tr.OddRow td a') || []
      even_links = @parser.absolute_url_list('table.FormTable tr.EvenRow td a') || []
      p links = odd_links.concat(even_links).uniq
      if links.empty?
        Hamster.report(
          to: @scraper_name,
          message: "project-#{Hamster::project_number} --download: no links in HTML: - \n #{browser.body} ",
          use: :both
        )
      end
      all_links.concat(links).uniq

      #raise StandardError.new("Test Parsing")

      if browser.css('table.pagingControls a')&.last&.text == "Next"
        browser.css('table.pagingControls a')&.last.focus.click
        sleep(15)
        raise StandardError.new("Pages still exist!")
      end
      #sleep(10)
    rescue => error
      puts error.message
      puts error.full_message
      retries += 1 if error.message.include?("Waited css not found.")
      if retries >= 23
        Hamster.report(
          to: @scraper_name,
          message: "project-#{Hamster::project_number} --download: Waited css not found used 10 retries \n#{error.full_message}",
          use: :both
        )
      end
      retry if error.message.include?("Pages still exist!") || error.message.include?("Waited css not found.") && retries < 25
    end
    #store
    p all_links
    save_links(all_links)
  end

  def save_links(links)
    links.each do |link|
      browser = @scraper.hammer_browser(
        url: link,
        sleep: 10,
        expected_css: "tr.TableHeading span#csNumber",
        headless: false
      )

      save_file(browser.body, "#{@converter.to_md5(browser.body.to_s)}.html", "html/court_info/")

      @parser.browser = browser

      # p @parser.case_activity
      # p @parser.case_party
      # p @parser.case_info
      # p @parser.case_additional_info

      case_activity, arr_pdf_lists, pdf_relation_indexes = @parser.case_activity

      @keeper_case_activty.upsert_all(case_activity)
      @keeper_case_party.upsert_all(@parser.case_party)
      @keeper_case_info.upsert_all(@parser.case_info)
      @keeper_additional_info.upsert_all(@parser.case_additional_info)

      case_activity.each_with_index do |data,index|
        if pdf_relation_indexes.include?(index)
          arr_pdf_lists.shift&.each do |pdf_link|
            puts "pdf_link=#{pdf_link}"
            save_activity_pdf(pdf_link, data[:court_id], data[:case_id], data[:md5_hash])
          end
        end
      end
      sleep(10)
    end
  end

  def save_activity_pdf(pdf_link, court_id, case_id, md5_activity)
    unless pdf_link.blank?
      file_name = "#{pdf_link.split('documentID=').last}.pdf"
      key = "us_courts_expansion_#{court_id}_#{case_id}_#{file_name}"
      content = @scraper.body(use: 'get_pdf', url: pdf_link, file_name: file_name.to_s, use_browser: true )
      upload_file_to_aws(content, key, pdf_link)
      pdf_data = {
        aws_link: "https://court-cases-activities.s3.amazonaws.com/#{key}",
        court_id: court_id,
        case_id: case_id,
        source_type: 'activities',
        source_link: pdf_link
      }
      md5_pdf_on_aws = @converter.to_md5(pdf_data)
      p pdf_data.merge!(md5_hash: md5_pdf_on_aws)
      #save_file(@parser.html, "CasePdfsOnAws_#{md5_pdf_on_aws}.html", "html/")
      @keeper_pdf_aws.upsert_all(pdf_data)
      p rel_data = {
        case_activities_md5: md5_activity,
        case_pdf_on_aws_md5: md5_pdf_on_aws,
        court_id: court_id
      }
      @keeper_rel_activ_pdf.upsert_all(false, rel_data)
    end
  end

  def upload_file_to_aws(content, key, source_link)
    @s3.put_file(content, key, metadata = { url: source_link })
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
    @keeper_case_info.update_touched_run_id
    @keeper_case_info.update_deleted
    @keeper_case_activty.update_touched_run_id
    @keeper_case_activty.update_deleted
    @keeper_case_party.update_touched_run_id
    @keeper_case_party.update_deleted
    @keeper_additional_info.update_touched_run_id
    @keeper_additional_info.update_deleted
    @keeper_pdf_aws.update_touched_run_id
    @keeper_pdf_aws.update_deleted
    @keeper_rel_activ_pdf.update_touched_run_id
    @keeper_rel_activ_pdf.update_deleted
    @runs.finish
    tars_to_aws
  end
end