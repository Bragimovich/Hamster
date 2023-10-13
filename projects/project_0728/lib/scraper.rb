# # require_relative '../../../lib/scraper'
require 'net/http'
require 'open-uri'
require 'fileutils'
require 'csv'

class Scraper < Hamster::Scraper

  def initialize
    super
    @cobble = Dasher.new(using: :cobble, redirect: true)
  end

  def fetch_main_page
    url = 'https://transparentdata.idaho.gov/data/#/29262/query=1F6B0A66BBD3AE3BCD77B1630B2D7CF4&embed=n'
    @cobble.get(url)
  end

  def fetch_csv_data(url)
     @cobble.get(url)
  end

  def get_aws_link_from_sub_page(query, max_retries = 3)
    url = "https://transparentdata.idaho.gov/data/#/#{query}"
    download_link = nil
    retries = 0

    while download_link.nil? && retries < max_retries
      browser = Ferrum::Browser.new(headless: true)

      browser.goto(url)
      xpath = "//button[normalize-space()='Just get started']"

      timeout = 30
      begin

        start_time = Time.now
        while (Time.now - start_time) < timeout
          element = browser.at_css('#App')
          break if element

          sleep 0.5
        end
      rescue Ferrum::NodeNotFoundError => e
       Hamster.logger.error(e.full_message)
       Hamster.report(to: 'Farzpal Singh', message: "#{Hamster::PROJECT_DIR_NAME}_#{@project_number}:\n#{e.full_message}", use: :slack)
      end
      # Raise an error if the element is not found within the specified timeout.
      button_element = browser.at_xpath(xpath)
      button_element.click if button_element
      #Extract the data using CSS selectors or XPath.
      button_css_selector = '.ui-dropdown__toggle.ui-button.small.ghost.no-color'
      wait_until_element_visible(browser, button_css_selector)
      click_element_with_js(browser, button_css_selector)
      button_css_selector = "//button[@class='ui-button primary block']"
      button_element = browser.at_xpath(button_css_selector)
      button_element.click if button_element

      yes_continue_button_css_selector = "//button[@class='ui-button primary']"
      yes_continue_button_element = browser.at_xpath(yes_continue_button_css_selector)
      yes_continue_button_element.click if yes_continue_button_element

      generating_file_css_selector = '.ui-loader__message'
      wait_until_element_not_visible(browser, generating_file_css_selector)

      xp = '//span[contains(text(), "Click to download:")]//following-sibling::p[contains(@class, "transaction-download")]/a'
      start_time = Time.now
      element = nil
      while (Time.now - start_time) < timeout
        element = browser.at_xpath(xp)
        break if element

        sleep 0.5
      end
      element
      download_link_element = element
      download_link = download_link_element.attribute('href') if download_link_element
      browser.quit

      if download_link.nil?
        retries += 1
      end
    end
    download_link
  end

  def wait_until_element_visible(browser, css_selector, timeout = 20)
    start_time = Time.now
    while (Time.now - start_time) < timeout
      visible = browser.evaluate("!!(document.querySelector('#{css_selector}') && document.querySelector('#{css_selector}').offsetParent)")
      break if visible

      sleep 0.5
    end
  end

  def wait_until_element_not_visible(browser, css_selector, timeout = 20)
    start_time = Time.now
    while (Time.now - start_time) < timeout
      visible = browser.evaluate("!!(document.querySelector('#{css_selector}') && document.querySelector('#{css_selector}').offsetParent)")
      break unless visible
      sleep 0.5
    end
  end

  def click_element_with_js(browser, css_selector)
    browser.evaluate("document.querySelector('#{css_selector}').click();")
  end

  def save_csv_file(case_ids, href)
        body = fetch_csv_data(href)
        formatted_body = csv_body(body)
        save_csv(formatted_body, case_ids)
  end


  def csv_body(file)
    body = []
    csv_b = CSV.parse(file)
    csv_b.drop(2).map do |row|
      body << row
    end
    formatted_csv_data = CSV.generate(headers: true) do |csv|
        body.each do |row|
          csv << row
        end
      end
      formatted_csv_data
  end

  def save_csv(content, id)
    FileUtils.mkdir_p "#{storehouse}store/#{id}"
    csv_path = "#{storehouse}store/#{id}/data.csv"
    File.open(csv_path, "wb") do |f|
      f.write(content)
    end
  end
end
