require 'socksify/http'
class Scraper < Hamster::Scraper

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

  def initialize
    super
    @hammer = Dasher.new(using: :hammer, headless: true)
    @browser = @hammer.connect
  end

  def get_files(run_id)
    search
    inspection
    file_name_updated('inspections', run_id)
    search
    citation
    file_name_updated('citations', run_id)
    close_browser
  end

  private

  def search
    landing_page
    dropdown
    sleep_wait
  end

  def inspection
    @browser.at_css("#exp-dt1").click
    sleep(10)
  end

  def citation
    @browser.at_css('#exp-dt3').click
    sleep(10)
  end

  def dropdown
    @browser.at_css("#expand-d").focus.click
    sleep(3)
  end

  def close_browser
    @hammer.close
  end

  def sleep_wait
    sleep(5)
    waiting_until_element_found('#exp-dt1')
  end

  def waiting_until_element_found(search)
    counter = 1
    element = element_search(search)
    loop do (element.nil?)
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
  
  def file_downloaded?
    counter = 1
    loop do
      sleep(3)
      puts "File Not Downloaded ---->>> #{counter}"
      break if Dir["#{storehouse}*.xlsx"].count > 0
      counter += 1
    end
  end

  def file_name_updated(file_name, run_id)
    sleep(10)
    create_folder_if_not_exists("#{storehouse}" + "store/#{run_id}")
    file_downloaded?
    old_filepath = Dir["#{storehouse}*.xlsx"].first
    new_filepath = File.join("#{storehouse}" + "store/#{run_id}", "#{file_name}.xlsx")
    FileUtils.mv(old_filepath, new_filepath)
  end

  def create_folder_if_not_exists(folder_path)
    unless Dir.exist?(folder_path)
      Dir.mkdir(folder_path)
    end
  end

  def landing_page
    @browser.go_to("https://datadashboard.fda.gov/ora/cd/inspections.htm")
    sleep(30)
  end
end
