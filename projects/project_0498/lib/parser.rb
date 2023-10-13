# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize(doc)
    @html = Nokogiri::HTML doc
  end

  def check_page_num
    @html.css('.pagination').css('.results-number').text.split.last.to_i
  end

  def nom_list
    @html.css('.expanded').css('.result-heading').css('a').map { |link| link.attr("href") }
  end

  def page_error(content, pn, id)
    body = content.body.strip
    proxy = content.env.request[:proxy][:uri].to_s
    ip = proxy.split('@').last.split(':').first
    port = proxy.split(':').last
    url = "https://www.congress.gov/nomination/117th-congress/#{pn}/all-info?r=#{id}"

    { ip: ip,
      port: port,
      proxy: proxy,
      url: url,
      body: body
    }
  end

  def congress_data(file)
    urls_in_action = []
    id = file.split('_').last.split('.').first.to_i

    if file.split('_').size == 9
      pn = file.split('_')[-3]
    else
      pn = file.split('_')[-4..-3].join('/')
    end

    title = @html.title
    nom_id = title.split(' - ')[0].strip
    congress_number = title.split('th Congress')[0].split(',').last.strip
    full_name = @html.css('.featured').css('h1').text.split('|').first.split('—')[1].split('117th').first.strip

    if full_name == "Army"
      full_name = nil
    elsif full_name == "Air Force"
      full_name = nil
    elsif full_name == "Navy"
      full_name = nil
    end

    overview = @html.css('.overview') 
    nom_desc = overview.at("h2:contains('Nominees')").next_element.children.text.strip rescue overview.at("h2:contains('Description')").next_element.children.text.strip rescue nil
    dept_name = overview.at("h2:contains('Organization')").next_element.children.text.strip
    date = overview.at("h2:contains('Date Received from President')").next_element.children.text.strip.split('/')
    date_received = Date.parse((date[2] + date[0] + date[1])).strftime("%Y-%m-%d")
    action_text = overview.at("h2:contains('Latest Action')").next_element.children.text.split('-').last.strip
    comm_name = overview.at("h2:contains('Committee')").next_element.children.text.strip
    main_wrapper = @html.css('.main-wrapper').last.css('p')
    action_table = @html.css('.main-wrapper').first.css('.expanded-actions')
    date_arr = action_table.css('tbody').css('tr').map { |el| el.css('td')[0].text.split('/') }
    date_action = date_arr.map { |el| Date.parse((el[2] + el[0] + el[1])).strftime("%Y-%m-%d")}
    senate_actions = action_table.css('tbody').css('tr').map { |el| el.css('td')[1].text }
    senate_url = action_table.css('tbody').css('tr').map { |el| el.css('td')[1].css('a').attr("href").text rescue nil }
    
    senate_url.map do |el|
      if el == nil
        urls_in_action << nil
      elsif el.split('/').size == 6
        urls_in_action <<  "https://www.congress.gov" + el rescue nil
      else
        urls_in_action << el
      end
    end

    nominee_text = main_wrapper.empty? ? nil : main_wrapper.text.split(':').first
    nom_status_table = main_wrapper.css('b').empty? ? nil : main_wrapper.css('b').text.gsub("To be", "").strip
    person_name = @html.css('.main-wrapper').last.css('tbody').css('tr').map { |el| el.css('td')[0].text }
    nominee_status = @html.css('.main-wrapper').last.css('tbody').css('tr').map { |el| el.css('td')[1].text rescue nom_status_table } 
    data_source_url = "https://www.congress.gov/nomination/117th-congress/#{pn}/all-info"

    {
      nom_id: nom_id,
      congress_number: congress_number,
      full_name: full_name,
      nom_desc: nom_desc,
      date_received: date_received,
      data_source_url: data_source_url,
      dept_name: dept_name,
      comm_name: comm_name,
      action_text: action_text,
      date_action: date_action,
      senate_actions: senate_actions,
      urls_in_action: urls_in_action,
      nominee_text: nominee_text,
      person_name: person_name,
      nominee_status: nominee_status
    }
  end
end
