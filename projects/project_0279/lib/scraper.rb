class Scraper <  Hamster::Scraper

  def initialize
    @hammer = Dasher.new(using: :hammer, headless: true)
    @browser = @hammer.connect
  end

  def get_file(storehouse, sub_folder)
    @browser.go_to("https://ofdsearch.doc.nv.gov/form.php")
    sleep(5)
    @browser.css('a').select{|e| e.text == 'Demographic'}.first.focus.click
    sleep(5)
    wait_time(storehouse)
    file_name_updated(storehouse, sub_folder, "demographic.csv")
    @browser.css('a').select{|e| e.text == 'Booking'}.first.focus.click
    wait_time(storehouse)
    file_name_updated(storehouse, sub_folder, "booking.csv")
    close_browser
  end

  private

  def wait_time(storehouse)
    sleep_counter = 1
    loop do
      sleep(sleep_counter)
      files = Dir["#{storehouse}*.csv"]
      break unless files.empty?
      sleep_counter += 1
      break if sleep_counter > 100
    end
  end

  def file_name_updated(file_path, sub_folder, file_name)
    sleep(10)
    create_folder_if_not_exists(file_path + "store/#{sub_folder}")
    old_filepath = File.join(file_path, file_name)
    new_filepath = File.join(file_path + "store/#{sub_folder}", file_name)
    FileUtils.mv(old_filepath, new_filepath)
  end

  def create_folder_if_not_exists(folder_path)
    unless Dir.exist?(folder_path)
      Dir.mkdir(folder_path)
    end
  end

  def close_browser
    @hammer.close
  end
end
