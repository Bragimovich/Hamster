# frozen_string_literal: true

class Georgia_scraper <  Hamster::Scraper

  def initialize
    @hammer = Dasher.new(using: :hammer, headless: true)
    @browser = @hammer.connect
  end

  def fetch_html(last_name,first_name)
    url = 'https://gdc.ga.gov/GDC/Offender/Query'
    browser.go_to(url)
    search_page(last_name,first_name)
    frame = switch_frame
    if empty_results(frame)
      return []
    elsif single_record_exists(frame)
      gdc_id = get_gdc_num(frame)
      puts "-----Processing GDC_Id => #{gdc_id}------"
      return [{"gdc_id": gdc_id, "html": frame.body}]
    else
      handling_pagination(frame)
    end
  end

  def close_browser
    hammer.close
  end

  private

  attr_reader :browser,:hammer

  def search_page(last_name,first_name)
    waiting_until_element_found(browser,'#iframe-content')
    frame = switch_frame
    tos_btn = waiting_until_element_found(frame,'#submit2')
    click_button(tos_btn) unless tos_btn.nil?
    last_name_field = waiting_until_element_found(frame,'#vLastName')
    first_name_field = waiting_until_element_found(frame,'#vFirstName')
    enter_text_into_field(last_name_field,last_name)
    enter_text_into_field(first_name_field,first_name)
    submit_btn = waiting_until_element_found(frame,'#NextButton2')
    click_button(submit_btn)
    waiting_until_element_found(browser,'#iframe-content')
  end

  def handling_pagination(frame)
    info_body_list = []
    total_pages = frame.css('span.oq-nav-btwn').first.text.split.last.to_i
    page_number = 1
    while page_number <= total_pages
      puts "Processing Page --->>> #{page_number}"
      info_btns = frame.css("input[value='View Offender Info']")
      break if info_btns.count == 0

      info_btns.each_with_index do |button,index|
        click_button(info_btns[index])
        waiting_until_element_found(browser,'#iframe-content')
        frame = switch_frame
        gdc_id = get_gdc_num(frame)
        puts "-----Processing GDC_Id => #{gdc_id}------"
        info_body_list << {"gdc_id": gdc_id, "html": frame.body}
        browser.back
        waiting_until_element_found(browser,'#iframe-content')
        frame = switch_frame
        info_btns = frame.css("input[value='View Offender Info']")
      end
      next_page = waiting_until_element_found(frame,'#oq-nav-nxt')
      click_button(next_page)
      waiting_until_element_found(browser,'#iframe-content')
      page_number += 1
    end
    info_body_list
  end

  def get_gdc_num(frame)
    frame.css('h5').select{|e| e.text.include? "GDC ID:"}.first.text.split(':').last.strip
  end

  def click_button(button)
    button.focus.click
  end

  def enter_text_into_field(field,text)
    field.focus.type(text)
  end

  def waiting_until_element_found(frame,search)
    counter = 1
    element = element_search(frame,search)
    while (element.nil?)
      element = element_search(frame,search)
      sleep 1
      break unless element.nil?
      counter +=1
      break if (counter > 10)
    end
    element
  end

  def element_search(frame,search)
    frame.at_css(search)
  end

  def empty_results(frame)
    return true if (frame.css("h3").count >= 1) && (frame.css("h3")[0].text.include? "Sorry, we couldn't find any offender records")
    false
  end

  def single_record_exists(frame)
    return true if (frame.css("h4").count >= 1) && (frame.css("h4")[0].text.include? "NAME:")
    false
  end

  def switch_frame
    frame_id = browser.frames.select{|e| e.name == 'iframe-content'}.first.id
    browser.frame_by(id: frame_id)
  end

end
