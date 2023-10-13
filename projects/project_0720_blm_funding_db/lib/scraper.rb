# frozen_string_literal: true

class Scraper < Hamster::Scraper
  
  def initialize
    super
    @hammer = Dasher.new(using: :hammer,  headless: true)
    @browser = @hammer.connect
  end

  def landing_page_ce
    browser.go_to(URL)
    cookie = browser.cookies.all.values[0].value
    cookies = "JSESSIONID=" + cookie
    sleep 10
  end
  
  def landing_page(url)
    browser.go_to(url)
    while true
      sleep 3
      doc = Nokogiri::HTML(browser.body)
      next if doc.css("div.rt-tbody div.rt-tr").size == 0
      js_loading_dropdown ="$('button.dropdown-toggle').click();"
      browser.execute(js_loading_dropdown)
      sleep 1
      next if doc.css('a.dropdown-item').size == 0
      break
    end
    sleep 2
  end

  def get_all_data
    items = []
    doc = Nokogiri::HTML(browser.body)
    doc.css("div.rt-tbody div.rt-tr").each_with_index do |row, index|
      columns = row.css('.rt-td')
      item = {
        contributor: columns[1].css('.rt-td-inner').text,
        amount_ori: columns[2].css('.rt-td-inner').text,
        follow_through: columns[3].css('.rt-td-inner').text,
        source: columns[4].css('.rt-td-inner a').map{|a_tag| a_tag.attr('href')}
      }
      item[:amount] = item[:amount_ori].split(".")[0].gsub(",", "").gsub("$", "").to_i rescue nil
      items << item
      # break if index > 3
    end
    items
  end

  def get_recipient_dropdown_items
    doc = Nokogiri::HTML(browser.body)
    items = []
    doc.css('a.dropdown-item').each do |a_tag|
      items << {id: a_tag.attr('id'), value: a_tag.css('.text').text } if a_tag.attr('id').include?("bs-select-2")
    end
    # doc.css('a.dropdown-item').map {|a_tag| a_tag.attr('id') if a_tag.attr('id').include?("bs-select-2") }.compact
    items
  end

  def get_location_dropdown_items
    doc = Nokogiri::HTML(browser.body)
    items = []
    doc.css('a.dropdown-item').each do |a_tag|
      items << {id: a_tag.attr('id'), value: a_tag.css('.text').text } if a_tag.attr('id').include?("bs-select-3")
    end
    # doc.css('a.dropdown-item').map {|a_tag| a_tag.attr('id') if a_tag.attr('id').include?("bs-select-3")}.compact
    items
  end

  def dropdown_change_with(dropdown_id, prev_dropdown_id = nil)
    
    time_out = 30
    js_remove_table = "document.querySelector('div.rt-table').innerHTML = '';"
    browser.execute(js_remove_table)
    js_script = "$('button.dropdown-toggle').click();" 
    time_out = 30
    while time_out > 0
      sleep 1
      doc = Nokogiri::HTML(browser.body)
      time_out -= 1
      next if doc.css('a.dropdown-item').size == 0
    end
    js_script = "document.getElementById('#{dropdown_id}').click();" 
    browser.execute(js_script)
    unless prev_dropdown_id.nil?
      js_script = "document.getElementById('#{prev_dropdown_id}').click();" 
      browser.execute(js_script)
      sleep 1
    end
    time_out = 30
    while time_out > 0
      sleep 1
      doc = Nokogiri::HTML(browser.body)
      break if doc.css('div.rt-tbody').size > 0
      time_out -= 1
    end
  end

  def show_detail(index)
    doc = Nokogiri::HTML(browser.body)
    if doc.css('button.rt-expander-button')[index].attr('aria-expanded') == "false"
      js_script = "$('button.rt-expander-button')[#{index}].click();"
      browser.execute(js_script)
      time_out = 30
      while time_out > 0
        sleep 1
        time_out -= 1
        doc = Nokogiri::HTML(browser.body)
        break if doc.css('div.rt-tr-details').size > 0
      end
    end
  end
  
  def hide_detail(index)
    doc = Nokogiri::HTML(browser.body)
    if doc.css('button.rt-expander-button')[index].attr('aria-expanded') == "true"
      js_script = "$('button.rt-expander-button')[#{index}].click();"
      browser.execute(js_script)
      time_out = 30
      while time_out > 0
        sleep 1
        time_out -= 1
        doc = Nokogiri::HTML(browser.body)
        break if doc.css('div.rt-tr-details').size == 0
      end
    end
  end

  def get_detail
    doc = Nokogiri::HTML(browser.body)
    doc.css('.rt-tr-details .rt-td-inner').text rescue nil
  end

  def close_browser
    browser.quit
  end
  
  private

    attr_accessor :browser

end
