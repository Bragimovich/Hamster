# frozen_string_literal: true

class Scraper < Hamster::Scraper

  def initialize
    super
    @keeper = Keeper.new
  end

  def download_pages
    count = 1
    downloaded_campuses = file_handling(downloaded_campuses, 'r', 'campus') rescue []
    start_browser
    browser.go_to('https://www.cusys.edu/budget/cusalaries/')
    waiting_until_element_found('#Value1_1')
    drop_down_values = browser.css('select option').map{ |e| e.text }[1...-1]
    drop_down_values.each do |value|
      next if (downloaded_campuses.include? value)
      drop_down = waiting_until_element_found('#Value1_1')
      drop_down.focus.type(value)
      search_btn = browser.css("input[type = 'submit']").first
      browser.execute("arguments[0].click()", search_btn)
      sleep (5)
      while true
        save_page(browser.body, "page_#{count}", "#{keeper.run_id}")
        count += 1
        next_btn = browser.css("a[data-cb-name = 'JumpToNext']").first
        break if (next_btn.nil?)
        browser.execute("arguments[0].click()", next_btn)
        sleep (2)
      end
      file_handling("#{value}", 'a', 'campus')
      browser.go_to('https://www.cusys.edu/budget/cusalaries/')
      waiting_until_element_found('#Value1_1')
    end
    close_browser
  end

  def close_browser
    hammer.close
  end

  private

  attr_reader :browser, :hammer, :keeper

  def waiting_until_element_found(search)
    counter = 1
    element = element_search(search)
    while (element.nil?)
      element = element_search(search)
      break unless element.nil?
      counter +=1
      break if (counter > 20)
    end
    element
  end

  def save_page(html, file_name, sub_folder)
    peon.put content: html, file: "#{file_name}", subfolder: sub_folder
  end

  def element_search(search)
    browser.at_css(search)
  end

  def start_browser
    @hammer = Dasher.new(using: :hammer, headless: true, proxy_filter: @proxy_filter)
    @browser = @hammer.connect
  end

  def file_handling(content, flag, file_name)
    list = []
    File.open("#{storehouse}store/#{@keeper.run_id}/#{file_name}.txt","#{flag}") do |f|
      flag == 'r' ? f.each {|e| list << e.strip } : f.write(content.to_s + "\n")
    end
    list unless list.empty?
  end

end
