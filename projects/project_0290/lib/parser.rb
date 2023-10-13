# frozen_string_literal: true

class MilwaukeeCountyParser < Hamster::Parser

  def convert_json_body(result_json)
    JSON.parse(result_json)
  end

  def event_date_parser(event_value, splitter)
    all_possible_scans = event_value.scan(/(([0-9])+([\/-])+([0-9])+([\/])+([0-9]){2,4})/).flatten.select{|e| e.size > 6}.uniq
    (all_possible_scans.empty?) ? nil : Date.strptime(all_possible_scans.last,'%m/%d/%Y')
  end

  def date_maker(year, date_of_event)
    if date_of_event.year.size == 2
      date_of_event = "#{year}-#{date_of_event.split("-")[1]}-#{date_of_event.split("-")[-1]}"
    end
    date_of_event
  end

  def datetime_based_conversion(date_value)
    begin
      DateTime.strptime(date_value, "%m/%d/%Y").to_date  
    rescue StandardError => e
      nil
    end    
  end

  def date_conversion(date_value)
    begin
      Date.parse(date_value)
    rescue StandardError => e
      nil
    end
  end

  def fetch_date_of_event(event_value)
    if event_value == nil or event_value == "" or event_value[/\d/].nil?  
      date_of_event = nil
    elsif event_value.split.first.include? 'Between'
      if event_value.split.second.include? '/'
        date_of_event = event_date_parser(event_value, '/')
      else
        date_of_event = event_date_parser(event_value, '-')
      end
    else
      begin
        if event_value.split.size > 1
          date_check = event_value.split.select{|s| s.include? "/" or s.include? "-"}
          if date_check.empty?
            date_of_event = date_conversion(event_value)
          elsif date_check.first.include? '-' and date_check.first.count('/') > 3
            date_of_event = date_conversion(event_value.split('-')[-1])
          else
            get_event = date_check.reject{|s| s.split("-").size == 2}

            if date_check.select{|e| e.include? "("}.count != 0
              date_of_event = nil
            elsif get_event.last.include? "-" and get_event.last.size != 1
              create_date = get_event.last.split("-")
              if create_date.count == 1
                get_date = get_event.first
              else
                (create_date[-1].size == 4) ? get_date = "#{create_date[-1]}-#{create_date[0]}-#{create_date[1]}" : get_date = "20#{create_date[-1]}-#{create_date[0]}-#{create_date[1]}"
              end
              date_of_event = date_maker("2021", date_conversion(get_date))
            elsif get_event[-1] == "-"
              date_of_event = date_maker(Date.today.year, datetime_based_conversion(get_event[0]))
            else
              date_of_event = date_maker(Date.today.year, datetime_based_conversion(get_event[-1]))
            end
          end
        else
          date_of_event = datetime_based_conversion(event_value)
          unless date_of_event.nil?
            date_of_event = date_maker(Date.today.year, date_of_event)
          end
        end
      rescue
        date_of_event = datetime_based_conversion(event_value)
      end
      unless date_of_event.nil?
        if date_of_event.year < 2000
          arr = [(date_of_event.month), (date_of_event.day), (date_of_event.year+2000)]
          arr = arr.join("/")
          date_of_event = datetime_based_conversion(arr)
        end
      end
    end
    date_of_event
  end

  def fetch_date_of_death(death_date, data_hash)
    if death_date == nil or death_date == ""
      data_hash[:date_of_death] = nil
    else
      in_seconds = death_date.to_i/1000
      stamp = Time.at(in_seconds).utc + (5*60*60)
      data_hash[:date_of_death] = stamp.to_date 
      data_hash[:time_of_death] = stamp.strftime("%I:%M:%S")
      data_hash[:period] = stamp.strftime("%p")
    end
    data_hash
  end

  def empty_nil(data_hash)
    data_hash.keys.each do |key|
      data_hash[key] = data_hash[key] == "" ? nil : data_hash[key]
    end
    data_hash
  end

  def parse_json(final)
    data_hash = {}
    data_hash[:case_number] = final["attributes"]["CaseNum"]
    data_hash[:case_type] = final["attributes"]["CaseType"]

    data_hash[:date_of_event] = fetch_date_of_event(final['attributes']['EventDate'])
    data_hash = fetch_date_of_death(final["attributes"]["DeathDate"], data_hash)
    data_hash[:year] = data_hash[:date_of_death].year rescue "-"
    
    data_hash[:age] = final["attributes"]["Age"]
    data_hash[:gender] = final["attributes"]["Gender"]
    data_hash[:race] = final["attributes"]["Race"]
    data_hash[:mode] = final["attributes"]["Mode"]
    data_hash[:cause_A] = final["attributes"]["CauseA"]
    data_hash[:cause_B] = final["attributes"]["CauseB"]
    data_hash[:cause_other] = final["attributes"]["CauseOther"]
    data_hash[:event_address] = final["attributes"]["EventAddr"]
    data_hash[:event_city] = final["attributes"]["EventCity"]
    data_hash[:event_state] = final["attributes"]["EventState"]
    data_hash[:event_zip] = final["attributes"]["EventZip"]
    data_hash = empty_nil(data_hash)
    data_hash
  end
end
