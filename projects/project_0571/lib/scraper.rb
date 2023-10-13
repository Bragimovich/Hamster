# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize
    @hammer = Dasher.new(using: :hammer, headless: true)
    @browser = @hammer.connect
  end

  def fetch_main_page(file_path, years, run_id)
    years.each do |current_year|
      url = 'https://dataportal.mt.gov/t/DOASITSDDataPortalPub/views/SABHRSStateEmployeeData/EmployeeDataDashboard?%3Aembed=y&%3AshowAppBanner=false&%3AshowShareOptions=true&%3Adisplay_count=no&%3AshowVizHome=no'
      @browser.go_to(url)
      waiting_until_element_found('div.tabComboBoxNameContainer')
      @browser.at_css('div.tabComboBoxButtonHolder').click
      @browser.css('div[role="listbox"] a').find { |element| element.text.to_i == current_year }.tap do |selected_year|
        selected_year.click
        sleep_wait
        waiting_until_element_found('div.tvimagesContainer')
        @browser.css('#download').first.click
        sleep_wait
        waiting_until_element_found('div[data-tb-test-id="download-flyout-download-crosstab-MenuItem"]')
        @browser.css('div[data-tb-test-id="download-flyout-download-crosstab-MenuItem"]').first.click
        sleep_wait
        waiting_until_element_found('button[data-tb-test-id="export-crosstab-export-Button"]')
        @browser.css('button[data-tb-test-id="export-crosstab-export-Button"]').first.click
        sleep(30)
        file_name_updated(file_path, current_year.to_s, run_id)
      end
    end
  end

  def close_browser
    @hammer.close
  end

  private

  def sleep_wait
    sleep(5)
    waiting_until_element_found('div.tvimagesContainer')
    sleep(5)
  end

  def waiting_until_element_found(search)
    counter = 1
    element = element_search(search)
    while (element.nil?)
      element = element_search(search)
      sleep 1
      break unless element.nil?
      counter +=1
      break if (counter > 15)
    end
    element
  end

  def element_search(search)
    @browser.at_css(search)
  end

  def click_button(button)
    button.click
  end
  
  def file_name_updated(file_path, year, run_id)
    sleep(10)
    create_folder_if_not_exists(file_path + "store/#{run_id}")
    old_filepath = File.join(file_path, "Employee Data Worksheet.xlsx")
    new_filepath = File.join(file_path + "store/#{run_id}", year + ".xlsx")
    FileUtils.mv(old_filepath, new_filepath)
  end

  def create_folder_if_not_exists(folder_path)
    unless Dir.exist?(folder_path)
      Dir.mkdir(folder_path)
  end
end
