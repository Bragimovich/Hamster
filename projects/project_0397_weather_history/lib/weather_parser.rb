# frozen_string_literal: true


class ParserWeather

  def initialize(loc_id=nil)
    @loc_id = loc_id
  end


  def parse_city_weather(json_html, url)
    json_html = json_html.split('<html><head></head><body><pre style="word-wrap: break-word; white-space: pre-wrap;">')[-1].split('</')[0]
    city_weather_hash = JSON.parse(json_html)
    current_ind = nil
    current_date = Date.today()
    md5_class = MD5Hash.new(:columns=>%i[loc_id date temperature pressure day_ind])
    weather_to_db = []
    p city_weather_hash['metadata']
    return if city_weather_hash['metadata']['status_code']>399
    weather_for_current_ind = []

    city_weather_hash['observations'].each do |weather|
      new_current_ind = weather['day_ind']

      if current_ind!=new_current_ind and !weather_for_current_ind.empty?
        count_weather_measurements = weather_for_current_ind.length
        sum_temperature = 0
        sum_pressure = 0
        sum_vis, sum_rh = 0, 0

        weather_for_current_ind.map do |measurement|
          sum_temperature+= measurement[:temperature] if !measurement[:temperature].nil?
          sum_pressure+= measurement[:pressure] if !measurement[:pressure].nil?
          sum_vis += measurement[:vis] if !measurement[:vis].nil?
          sum_rh += measurement[:rh] if !measurement[:rh].nil?
        end

        weather_to_db.push({
                             loc_id: @loc_id,
                             temperature: sum_temperature/count_weather_measurements,
                             pressure: sum_pressure/count_weather_measurements,
                             day_ind: current_ind,
                             date: Time.at(weather_for_current_ind[count_weather_measurements/2][:date_unix]).to_datetime,
                             data_source_url: url,

                             wx_phrase: weather_for_current_ind[count_weather_measurements/2][:wx_phrase],
                             dewPt: weather_for_current_ind[count_weather_measurements/2][:dewPt],
                             heat_index: weather_for_current_ind[count_weather_measurements/2][:heat_index],
                             rh: sum_rh/count_weather_measurements,
                             vis: sum_vis/count_weather_measurements,
                           })
        weather_to_db[-1][:md5_hash] = md5_class.generate(weather_to_db[-1])
        weather_for_current_ind = []
      end
      current_ind = new_current_ind
      #new_date_in_element = Time.at(weather['valid_time_gmt'].to_i).to_datetime

      weather_for_current_ind.push({
                                     temperature: weather['temp'],
                                     pressure:    weather['pressure'],
                                     date_unix:   weather['valid_time_gmt'],
                                     wx_phrase:   weather['wx_phrase'],
                                     dewPt:       weather['dewPt'],
                                     heat_index:  weather['heat_index'],
                                     rh:          weather['rh'],
                                     vis:         weather['vis'],
                                   })



    end
    weather_to_db

  end

  def self.parse_main_page(html_page)
    doc = Nokogiri::HTML(html_page)

    begin
      all_page = doc.css('.pagination').css('.results-number')[0].content.split('of ')[-1].gsub(',','').to_i
    rescue =>e
      all_page = 500
    end

    basic = doc.css('.basic-search-results-lists')
    records = []

    basic.css(".expanded").each do |row|
      records.push({})
      heading = row.css('.result-heading')[0].css('a')[0]
      records[-1][:leg_id] = heading.content.split(";")[0]
      records[-1][:link] = MAINURL + heading['href'].split("?")[0] #.join("/")
    end

    return records, all_page
  end

end


class ParserOnePage

  MAINURL = "https://www.congress.gov"

  def initialize(**record)
    @title = record[:leg_id]
    @link = record[:link]
  end


  def parse_article_page(html_page)
    doc = Nokogiri::HTML(html_page)
    @body = doc#.css('.all-info-wrapper')[0]

    legislation = {}
    if not doc.css('h1')[0].content.match("We couldn't find that page")
      legislation[:subjects] = get_subjects
      legislation[:info] = [get_info]
      legislation[:actions_overview] = get_actions_overview
      legislation[:actions] = get_actions
      legislation[:committees] = get_committees
      legislation[:cosponsors] = get_cosponsors
      legislation[:related_bills] = get_related_bills
    end
    legislation

  end

  def get_link_to_text
    @body.css('a#view-text-link')[0]['href']
  end

  def get_info
    info = {leg_id: @title, data_source_url: @link,}

    leg_detail = @body.css('.legDetail')[0]


    info[:congress_number] = leg_detail.css('span')[0].content.split('|')[0].strip

    overview_nokogiri = @body.css('.overview')
    sponsor = overview_nokogiri.css('table.standard01').css('tr td').css('a')[0]

    summary = @body.css('#latestSummary-content #bill-summary')[0]
    if !summary.nil?
      summary = summary.css('p')[-1]
      summary = summary.content.strip if !summary.nil?
    end

    if !sponsor.nil?
      info[:sponsor_link] = MAINURL + sponsor['href']
      info[:sponsor_name] = sponsor.content.split('[')[0].strip
      regular_sponsor_id = sponsor.content.match(/\[(.*?)\]/)
      info[:sponsor_id] = regular_sponsor_id[1] if !regular_sponsor_id.nil?
    end
    info[:status] = overview_nokogiri.css('li.selected')[0].content.split("\n")[0].split("Array")[0] if !overview_nokogiri.css('li.selected')[0].nil?
    info[:short_description] = @body.css('#titles_main .titles-row p')[0].content.strip if !@body.css('#titles_main .titles-row p')[0].nil?
    info[:description] = @body.css('.officialTitles .house-column p')[0].content.strip if !@body.css('.officialTitles .house-column p')[0].nil?
    info[:summary] = summary

    #info[:text_link] = @body.css('a#view-text-link')[0]['href']

    info
  end


  def get_actions_overview
    actions = []

    actions_nokogiri = @body.css('#actionsOverview-content')

    actions_nokogiri.css('tbody').css('tr').each do |tr|
      date = tr.css('td.date')[0]
      action_text = tr.css('td.actions')[0]
      actions.push({leg_id: @title, data_source_url: @link,
                     date: nil, action_text: nil,  related: nil})

      actions[-1][:date] = Date.strptime(date.content, '%m/%d/%Y') if !date.nil?

      if !action_text.nil?

        related = {}
        action_text.css('a').each do |a|
          related[a.content] = MAINURL + a['href']
        end

        actions[-1][:action_text] = action_text.content
        actions[-1][:related] = related.to_json
      end
    end
    actions
  end


  def get_actions
    actions = []

    actions_nokogiri = @body.css('#allActions-content')

    actions_nokogiri.css('tbody').css('tr').each do |tr|
      date = tr.css('td.date')[0]
      action_text = tr.css('.actions')[0]
      actions.push({leg_id: @title, data_source_url: @link,
                    date: nil, action_text:nil,  action_by: nil, related:nil})

      if !date.nil?
        actions[-1][:date] =
          if date.content.match('-')
            DateTime.strptime(date.content, '%m/%d/%Y-%I:%M%p')
          else
            DateTime.strptime(date.content, '%m/%d/%Y')
          end
      end

      if !action_text.nil?
        related = {}
        action_text.css('a').each do |a|
          related[a.content] = a['href']
        end

        divided_action_text = action_text.content.split("Action By: ")
        actions[-1][:action_text] = divided_action_text[0]
        actions[-1][:action_by] = divided_action_text[1]  if divided_action_text.length>1
        actions[-1][:related] = related.to_json
      end
    end
    actions
  end

  def get_cosponsors
    cosponsors = []
    cosponsor_nokogiri = @body.css('#cosponsors-content')
    md5_class = MD5Hash.new(:columns=>%i[leg_id name date sponsor_id link])
    cosponsor_nokogiri.css("tbody").css("tr").each do |cosponsor|
      title_cos = cosponsor.css('.actions')[0]
      cosponsors.push({
                        leg_id: @title, data_source_url: @link,
                        date:nil
                      })
      cosponsors[-1][:name] = title_cos['data-text']
      link = title_cos.css('a')[0]

      date = cosponsor.css('.date')[0]

      cosponsors[-1][:link] = !link.nil? ? link['href'] : nil
      cosponsors[-1][:sponsor_id] = !link.nil? ? link.content.match(/\[(.*?)\]/)[1] : nil
      cosponsors[-1][:date] = Date.strptime(date.content, '%m/%d/%Y') if !date.nil?
      cosponsors[-1][:md5_hash] = md5_class.generate(cosponsors[-1])
    end
    cosponsors
  end

  def get_committees
    committees = []
    committee_nokogiri = @body.css('#committees-content')

    md5_class = MD5Hash.new(:columns=>%i[leg_id committee date activity related])

    committee_nokogiri.css("table.table_committee tbody").css("tr").each do |committee|
      committee_name = committee.css('.names')[0]
      next if committee_name.nil?
      date = committee.css('td')[0]
      activity = committee.css('td')[1]
      related_nokogiri = committee.css('td')[2].css('a')[0]
      related =
        if related_nokogiri
         {committee.css('td')[2].css('a')[0].content => committee.css('td')[2].css('a')[0]['href']}.to_json
        end

      committees.push({leg_id: @title, data_source_url: @link,
                        committee: committee_name.content})

      committees[-1][:date]     =
        if !date.nil?
          Date.strptime(date.content, '%m/%d/%Y') if date.content.match(/\d{2}\/\d{2}\/\d{4}/)
        end
      committees[-1][:activity] = !activity.nil? ? activity.content : nil
      committees[-1][:related]  = related
      committees[-1][:md5_hash] = md5_class.generate(committees[-1])
    end
    committees
  end

  def get_related_bills
    related_bills = []
    related_bill_nokogiri = @body.css('#relatedBills-content')

    related_bill_nokogiri.css("table.item_table tbody").css('tr').each do |tr|

      related_bill = {
        leg_id: @title, data_source_url: @link,
        date: nil, latest_action:nil, link:nil, bill_id:nil,
      }

      td = tr.css('td')
      bill = td.css('a')[0]

      if !bill.nil?
        related_bill[:link] = bill['href']
        related_bill[:bill_id] = bill.content
      end

      title = td[1]
      relations_HR6000 = td[2]
      relations_identified = td[3]
      latest_action = td[4]

      related_bill[:title] = title ? title.content : nil
      related_bill[:relations_HR6000] = relations_HR6000 ? relations_HR6000.content : nil
      related_bill[:relations_identified] = relations_identified ? relations_identified.content : nil

      if !latest_action.nil?
        related_bill[:date] = Date.strptime(latest_action.content.split(' ')[0], '%m/%d/%Y')
        related_bill[:latest_action] = latest_action.content.split(' ')[1]
      end

      related_bills.push(related_bill)
    end

    related_bills
  end

  def get_amendments

  end

  def get_subjects
    subjects = []
    @body.css('#subjects-content').css('.plain').each do |subj_html|
      subj_link_nokogiri = subj_html.css('a')[0]
      if subj_link_nokogiri
        subj_link =
          if subj_link_nokogiri['href'].match(/^\//)
            "https://www.congress.gov" + subj_link_nokogiri['href']
          else
            subj_link_nokogiri['href']
          end
        subjects.push({
                        leg_id: @title, data_source_url: @link,
                        subject_name: subj_link_nokogiri.content,
                        link: subj_link,
                      })
      end
    end
    subjects
  end

  def get_text(html_text)
    doc = Nokogiri::HTML(html_text)
    md5_class = MD5Hash.new(:columns=>%i[leg_id pdf_link ])
    text = doc.css('.generated-html-container')[0]
    text_hash = {leg_id: @title, data_source_url: @link,
      text_html:nil, pdf_link:nil}

    if doc.css('#textSelector #textVersion')[0]
      text_hash[:another_texts] = []
      doc.css('#textSelector #textVersion').css('option').each do |option|
        next if option['selected']
        text_hash[:another_texts].push(option['value'])
      end
    end

    if !text.nil?
      text_hash[:text_html] = text.to_s
      doc.css('#bill-summary').css('li a').each do |link|
        text_hash[:pdf_link] = MAINURL + link['href'] if link.content.match(/PDF/)
      end
    end

    text_hash[:md5_hash] = md5_class.generate(text_hash)
    p text_hash[:md5_hash]
    text_hash
  end

end