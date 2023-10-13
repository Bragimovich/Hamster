# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize
    super
    @keeper = Keeper.new
  end

  def download_candidate_data
    total_pages_traversed = get_total_pages
    start_browser
    url = 'https://publicreporting.elections.ny.gov/ActiveDeactiveFiler/ActiveDeactiveFiler'
    body = 'strFilerID=1'
    browser.go_to(url)
    sleep (15)
    search_btn = waiting_until_element_found('#btnCommonSearch')
    click_button(search_btn)
    sleep (20)
    page_no = 1
    candidate_count = 1
    browser.css('#listOfFilerGrid_wrapper select').first.focus.type('100')
    while true
      if ((total_pages_traversed.nil?) || ((total_pages_traversed != nil) && (page_no > total_pages_traversed)))
        buttons = browser.css('.CandidateClick')
        buttons.each_with_index do |button,index|
          page = Nokogiri::HTML(browser.body.force_encoding('utf-8'))
          filer_id = page.css('.CandidateClick')[index].parent.parent.css('td.sorting_1').first.text
          browser.execute("arguments[0].click()", button)
          sleep (1.5)
          save_page("#{browser.body} => #{filer_id}", "can_#{candidate_count}", "#{keeper.run_id}/candidate/page_#{page_no}")
          candidate_count += 1
        end
      end
      page_no += 1
      next_btn_class = browser.css('.next')[0].attribute('class')
      break if (next_btn_class.include? 'disabled')
      browser.execute('document.querySelector(".next").click()')
      sleep (1.5)
    end
    close_browser
  end

  def download_fmt_files(url, key, file_name, run_id)
    browser.go_to(url)
    sleep (60)
    download_btn = waiting_until_element_found('#exportToExcel')
    browser.execute("arguments[0].scrollIntoView(true)", download_btn)
    click_button(download_btn)
    check_downloaded_file(key, file_name, run_id)
  end

  def download_nys_filer_file(key, file_name, run_id)
    start_browser
    browser.go_to('https://publicreporting.elections.ny.gov/ActiveDeactiveFiler/ActiveDeactiveFiler')
    sleep (10)
    search_btn = waiting_until_element_found('#btnCommonSearch')
    click_button(search_btn)
    sleep (30)
    browser.execute('document.querySelector("#btnCSVDownloadData").click()')
    check_downloaded_file(key, file_name, run_id)
    close_browser
  end

  def download_nys_compaign_files(run_id)
    downloaded_files = Dir["#{storehouse}store/#{run_id}/**/*.zip"].map{ |e| e.split('/').last }
    start_browser
    years = get_years
    years.each do |year|
      year_drop_down = waiting_until_element_found('#lstUCYearDCF')
      year_drop_down.focus.type(year)
      sleep (2)
      report_drop_down = waiting_until_element_found('#lstFilingDesc')
      report_options = report_drop_down.css('option').map{ |e| e.text.squish }.reject{ |e| e.downcase.include? 'select' }
      report_options.each do |report_option|
        report_drop_down.focus.type(report_option)
        sleep (2)
        file_name = "#{year}_#{report_option}"
        next if (downloaded_files.include? file_name)
        browser.execute('document.querySelector("#btnCSVPDF").click()')
        check_downloaded_file('zip', file_name, run_id, 'zip', 100)
      end
      years = get_years
    end
    close_browser
  end

  def start_browser
    @hammer = Dasher.new(using: :hammer, headless: false, proxy_filter: @proxy_filter)
    @browser = @hammer.connect
  end

  def close_browser
    hammer.close
  end

  private

  attr_reader :browser, :hammer, :keeper

  def get_years
    browser.go_to('https://publicreporting.elections.ny.gov/DownloadCampaignFinanceData/DownloadCampaignFinanceData')
    sleep (10)
    data_type_drop_down = waiting_until_element_found('#lstDateType')
    data_type_drop_down.focus.type('Disclosure Report')
    sleep (2)
    ('2016'..Date.today.year.to_s).map(&:to_s)
  end

  def check_downloaded_file(key, file_name, run_id, ext = 'csv', wait_time = 1000)
    time = Time.now.to_i + wait_time
    while true
      break if Time.now.to_i >= time
      file = Dir["#{storehouse}*.#{ext}"].reject{ |e| e.to_s.downcase.include? 'un'}.first.to_s
      if (file.include? key)
        FileUtils.mkdir_p "#{storehouse}store/#{run_id}"
        FileUtils.mv("#{storehouse}#{file.split('/').last}","#{storehouse}store/#{run_id}/#{file_name}.#{ext}")
        break
      else
        sleep (2)
      end
    end
  end

  def click_button(btn)
    btn.click
  end

  def waiting_until_element_found(search)
    counter = 1
    element = element_search(search)
    while (element.nil?)
      element = element_search(search)
      sleep 2
      break unless element.nil?
      counter +=1
      break if (counter > 20)
    end
    element
  end

  def element_search(search)
    browser.at_css(search)
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html, file: "#{file_name}", subfolder: sub_folder
  end

  def get_total_pages
    peon.list(subfolder: "#{keeper.run_id}/candidate/").map{ |e| e.split('_').last.to_i }.sort[0...-1].last rescue nil
  end

end
