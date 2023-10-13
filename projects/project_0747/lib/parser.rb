# frozen_string_literal: true

class Parser < Hamster::Parser
  attr_writer :county, :token, :link, :run_id
  def initialize(doc)
    @html = Nokogiri::HTML doc
  end

  def parse_main_page
    [
      @html.css("input[name='token']").attr("value").text,
      @html.css("select[name='COUNTY']").css('option').map { |value| value.attr("value") }
    ]
  end

  def parse_list
    @html.css('tbody').css('tr').map { |tr| { data_source_url: "https://apps.ark.org/inmate_info/" + tr.css('td').css('a').attr("href").text, number: tr.css('td').css('a').attr("href").text.split("&").first.split('=').last }}
  end

  def next_page
    url = @html.css("div[class='pagelink']").last.css('a').attr("href").value rescue nil
    url.nil? ? ["https://apps.ark.org/inmate_info/search.php?COUNTY=#{@county}&sex=b&agetype=1&RUN=1&disclaimer=1&token=#{@token}", nil] : ["https://apps.ark.org/inmate_info/" +  url]
  end

  def page_number
    @html.css("div[class='pagelink']").last.css('a').attr("href").value.split("&").select {|num| num.include?("RUN") }.join.split('=').last rescue nil
  end

  def parse_info
    hash = Hash.new
    hash.merge!(inmate: inmate_hash)
    hash.merge!(arrest_arr: arrest_arr)
    hash.merge!(addresses_hash: addresses_hash)
    hash.merge!(holding_facilities_hash: holding_facilities_hash)
    hash.merge!(inmate_ids_hash: inmate_ids_hash)
    hash.merge!(inmate_ids_additional_arr: inmate_ids_additional_arr)
    hash.merge!(inmate_aliases_arr: inmate_aliases_arr)
    hash.merge!(mugshots_hash: mugshots_hash)
    hash.merge!(inmate_additional_info_arr: inmate_additional_info_arr)
    hash.merge!(program_achievements_arr: program_achievements_arr) unless program_achievements_arr.nil?
    hash.merge!(disciplinary_violations_arr: disciplinary_violations_arr) unless disciplinary_violations_arr.nil?
    hash.merge!(arkansas_charges: arkansas_charges)
    hash
  end
  
  def inmate_hash
    {
      full_name: info[:full_name],
      birthdate: info[:birthdate],
      sex: info[:sex],
      race: info[:race],
      data_source_url: @link,
      run_id: @run_id,
      touched_run_id: @run_id
    }
  end

  def arrest_arr
    arrest_arr = []
    detainers.each do |row|
      hash = {
        inmate_id: nil,
        booking_date: row[:booking_date],
        booking_agency: row[:booking_agency],
        data_source_url: @link,
        run_id: @run_id,
        touched_run_id: @run_id
      }
      arrest_arr << hash
    end
    arrest_arr
  end

  def addresses_hash
    {
      full_address: "Facility Address = #{info[:facility_address]}; Mailing Address = #{info[:mailing_address]}",
      data_source_url: @link,
      run_id: @run_id,
      touched_run_id: @run_id
    }
  end

  def holding_facilities_hash
    {   
      arrest_id: nil,
      holding_facilities_addresse_id: nil,
      facility: info[:facility],
      facility_subtype: info[:facility_subtype],
      start_date: info[:start_date],
      planned_release_date: info[:planned_release_date],
      total_time: info[:total_time],
      data_source_url: @link,
      run_id: @run_id,
      touched_run_id: @run_id
    }
  end

  def inmate_ids_hash
    {  
      inmate_id: nil,
      number: info[:number],
      type: info[:type],
      date_from: info[:date_from],
      data_source_url: @link,
      run_id: @run_id,
      touched_run_id: @run_id
    }
  end

  def inmate_ids_additional_arr
    additional_info_arr = []
    unless probation.empty?
      probation.each do |row|
        row.each do |key, value|
          if key == (:sis) || key == (:probation)
            unless value.empty?
              hash = {
                  key: key,
                  value: value,
                  arkansas_inmate_ids_id: nil,
                  run_id: @run_id,
                  touched_run_id: @run_id
                }
              additional_info_arr <<  hash
            end
          end
        end
      end
    end

    unless probation_history.empty?
      probation_history.each do |row|
        row.each do |key, value|
          if key == (:sis) || key == (:probation)
            unless value.empty?
              hash = {
                  key: key,
                  value: value,
                  arkansas_inmate_ids_id: nil,
                  run_id: @run_id,
                  touched_run_id: @run_id
                }
              additional_info_arr << hash
            end
          end
        end
      end
    end
    additional_info_arr
  end

  def inmate_aliases_arr
    aliases_arr = []
    unless aliases.empty?
      aliases.each do |row|
        unless row.empty?
          hash = {
            inmate_id: nil,
            full_name: row.strip,
            data_source_url: @link,
            run_id: @run_id,
            touched_run_id: @run_id
            }
          aliases_arr << hash
        end
      end
    end
    aliases_arr
  end

  def mugshots_hash
    unless aws_link.nil?
      {
        inmate_id: nil,
        original_link: aws_link,
        data_source_url: @link,
        run_id: @run_id,
        touched_run_id: @run_id
      }
    end
  end

  def inmate_additional_info_arr
    additional_info_arr = []
    info.each do |row, value|
      if row == (:hair_color) || row == (:eye_color) || row == (:height) || row == (:weight) || row == (:birthdate) || row == (:age)  || row == (:custody_classification) 
        unless value.nil? || value.empty?
          hash = {
              key: row,
              value: value,
              inmate_id: nil,
              run_id: @run_id,
              touched_run_id: @run_id
            }
          additional_info_arr << hash
        end
      end
    end

    unless description.empty?
      description.each do |row|
        hash = {
          key: "tattoo",
          value: row,
          inmate_id: nil,
          run_id: @run_id,
          touched_run_id: @run_id
        }
        additional_info_arr << hash
      end
    end

    unless risk_score.empty?
      risk_score.each do |row|
        row.each do |row, value|
          unless value.nil? || value.empty?
            hash = {
                key: row,
                value: value,
                inmate_id: nil,
                run_id: @run_id,
                touched_run_id: @run_id
              }
            additional_info_arr << hash
          end
        end
      end
    end
    additional_info_arr
  end

  def program_achievements_arr
    unless achievements.empty?
      achievement_arr = []
      achievements.each do |row|
        hash = {
          inmate_id: nil,
          achievement: row[:achievement],
          date_of_completion: row[:date_of_completion],
          data_source_url: @link,
          run_id: @run_id,
          touched_run_id: @run_id
        }
        achievement_arr << hash
      end
      achievement_arr
    end
  end

  def disciplinary_violations_arr
    unless disciplinary_violations.empty?
      disciplinary_arr = []
      disciplinary_violations.each do |row|
        hash = {
          inmate_id: nil,
          disciplinary_violation: row[:violation],
          date: row[:violation_date],
          data_source_url:  @link,
          run_id: @run_id,
          touched_run_id: @run_id
        }
        disciplinary_arr << hash
      end
      disciplinary_arr
    end
  end

  def arkansas_charges
    charges_arr = []
    court_hearings_arr = []
    court_hearings_additional_arr = []
    additional_arr = []
    charges_additional_arr = []
    charge_arr_d = []
    unless prison_sentence.empty?
      prison_sentence.each do |row|
        charge_hash = {
          inmate_id: nil,
          crime_class: row[:crime_class],
          data_source_url: @link,
          run_id: @run_id,
          touched_run_id: @run_id
          }
        ch_hash = {
          charge_id: nil,
          court_date: row[:court_date],
          case_number: row[:case_number],
          sentence_lenght: row[:sentence_lenght],
          data_source_url: @link,
          run_id: @run_id,
          touched_run_id: @run_id
          }
        cha_hash = {
          key: "county" ,
          value: row[:county] ,
          arkansas_court_hearings_id: nil,
          run_id: @run_id,
          touched_run_id: @run_id
          }
        charges_arr << charge_hash
        court_hearings_arr << ch_hash
        court_hearings_additional_arr << cha_hash
      end
    end
    unless prison_sentence_history.empty?
      prison_sentence_history.each do |row|
        charge_hash = {
          inmate_id: nil,
          crime_class: row[:crime_class],
          data_source_url: @link,
          run_id: @run_id,
          touched_run_id: @run_id
          }
        ch_hash = {
          charge_id: nil,
          court_date: row[:court_date],
          case_number: row[:case_number],
          sentence_lenght: row[:sentence_lenght],
          data_source_url: @link,
          run_id: @run_id,
          touched_run_id: @run_id
          }
        cha_hash = {
          key: "county" ,
          value: row[:county] ,
          arkansas_court_hearings_id: nil,
          run_id: @run_id,
          touched_run_id: @run_id
          }
        charges_arr << charge_hash
        court_hearings_arr << ch_hash
        court_hearings_additional_arr << cha_hash
      end
    end
    unless probation.empty?
      probation.each do |row|
        charge_hash = {
          inmate_id: nil,
          crime_class: row[:crime_class],
          data_source_url: @link,
          run_id: @run_id,
          touched_run_id: @run_id
          }
        ch_hash = {
          charge_id: nil,
          court_date: row[:court_date],
          case_number: row[:case_number],
          sentence_lenght: row[:sentence_lenght],
          data_source_url: @link,
          run_id: @run_id,
          touched_run_id: @run_id
          }
        cha_hash = {
          key: "county" ,
          value: row[:county] ,
          arkansas_court_hearings_id: nil,
          run_id: @run_id,
          touched_run_id: @run_id
          }
        charges_arr << charge_hash
        court_hearings_arr << ch_hash
        court_hearings_additional_arr << cha_hash
      end
    end
    unless probation_history.empty?
      probation_history.each do |row|
        charge_hash = {
          inmate_id: nil,
          crime_class: row[:crime_class],
          data_source_url: @link,
          run_id: @run_id,
          touched_run_id: @run_id
          }
        ch_hash = {
          charge_id: nil,
          court_date: row[:court_date],
          case_number: row[:case_number],
          sentence_lenght: row[:sentence_lenght],
          data_source_url: @link,
          run_id: @run_id,
          touched_run_id: @run_id
          }
        cha_hash = {
          key: "county" ,
          value: row[:county] ,
          arkansas_court_hearings_id: nil,
          run_id: @run_id,
          touched_run_id: @run_id
          }
        charges_arr << charge_hash
        court_hearings_arr << ch_hash
        court_hearings_additional_arr << cha_hash
      end
    end
    unless detainers.empty?
      detainers.each do |row|
        charge_hash = {
          inmate_id: nil,
          crime_class: row[:crime_class],
          data_source_url: @link,
          run_id: @run_id,
          touched_run_id: @run_id
        }
        charge_arr_d << charge_hash
        row.each do |row, value|
          if row == (:type) || row == (:date_cancelled)
            unless value.nil?
                hash = {
                  key: row,
                  value: value,
                  arkansas_charges_id: nil,
                  run_id: @run_id,
                  touched_run_id: @run_id
                }
                charges_additional_arr << hash
            end
          end
        end
      end
    end
    [charges_arr, court_hearings_arr, court_hearings_additional_arr, charge_arr_d, charges_additional_arr]
  end

  def aws_link
    @html.css('.inmateinfo').css("div[class='photo']").css('img').attr("src").text rescue nil
  end

  def info
    head = [
      :number, :full_name, :race, :sex, :hair_color, :eye_color, :height, :weight, :birthdate, :start_date,
      :facility, :facility_address, :mailing_address, :custody_classification, :facility_subtype, :planned_release_date, :total_time, :type, :com1, :com2
    ]
    hash = {}
    @html.css('.inmateinfo').css("div[class='col-sm-7']").css("div[class='row']").each_with_index do |value, index|
      hash[head[index]] = value.css("div[class='col-xs-6']").text.gsub(" Map","").gsub(" Map","").strip
      hash
    end
    hash.merge!({
      birthdate: parse_date(hash[:birthdate]),
      start_date: parse_date(hash[:start_date]),
      date_from: hash[:start_date],
      age: calculate_age(hash[:birthdate]),
      planned_release_date: parse_date(hash[:planned_release_date])
      })
    hash
  end

  def aliases
    row = @html.css('.inmateinfo').css("div[class='col-sm-6']").first
    row.css('h3').remove
    arr = row.children.text.strip.gsub("\n",",").split(',')
    arr.delete_if {|value| value.strip.empty? }
    arr
  end

  def description
    row = @html.css('.inmateinfo').css("div[class='col-sm-6']").last
    row.css('h3').remove
    row.children.text.strip.gsub(/\r\n/,'').gsub("\n","").split.map { |val| val.strip }.join(" ").split(". ")
  end

  def prison_sentence
    arr = parse_table([:crime_class, :court_date, :county, :case_number, :sentence_lenght ], 2)
    arr.each do |row|
      row.merge!({court_date: parse_date(row[:court_date])})
    end
    arr
  end

  def prison_sentence_history
    arr = parse_table([ :crime_class, :court_date, :county, :case_number, :sentence_lenght ], 3)
    arr.each do |row|
      row.merge!({court_date: parse_date(row[:court_date])})
    end
    arr
  end

  def detainers
    arr = parse_table([ :booking_date, :booking_agency, :crime_class, :type, :date_cancelled ], 4)
    if arr.empty?
      arr = [booking_agency: "Not Data"]
    end 
    arr.each do |row|
      row.merge!({booking_date: parse_date(row[:booking_date]), date_cancelled: parse_date(row[:date_cancelled])})
    end
    arr
  end

  def disciplinary_violations
    arr = parse_table([ :violation, :violation_date ], 5)
    arr.each do |row|
      row.merge!({violation_date: parse_date(row[:violation_date])})
    end
    arr
  end

  def risk_score
    arr = parse_table([ :agency, :date_compleated, :level ], 6)
    arr.each do |row|
      row.merge!({date_compleated: parse_date(row[:date_compleated])})
    end
    arr
  end

  def probation
    arr = parse_table([ :crime_class, :court_date, :county, :case_number, :sentence_lenght, :sis, :probation ], 9)
    arr.each do |row|
      row.merge!({court_date: parse_date(row[:court_date]), sentence_lenght: row[:probation]})
    end
    arr
  end

  def probation_history
    arr = parse_table([ :crime_class, :court_date, :county, :case_number, :sentence_lenght, :sis, :probation ], 10)
    arr.each do |row|
      row.merge!({court_date: parse_date(row[:court_date]), sentence_lenght: row[:probation]})
    end
    arr
  end

  def achievements
    arr = parse_table([ :achievement, :date_of_completion ], 8)
    arr.each do |row|
      row.merge!({date_of_completion: parse_date(row[:date_of_completion])})
    end
    arr
  end

  private

  def calculate_age(value)
    (Time.now.strftime("%Y").to_i - (Date.parse(value).strftime("%Y").to_i)).to_s rescue nil
  end

  def parse_date(date)
    raw_date = date.split("/") rescue nil
    Date.parse((raw_date[2] + raw_date[0] + raw_date[1])).strftime("%Y-%m-%d") rescue nil
  end

  def parse_table(head, table_row)
    arr = []
    @html.css('.inmateinfo').css("div[class='row no-pb']")[table_row].css("table").css("tbody").css("tr").each do |row|
      hash = {}
      row.css("td").each_with_index do |value, index|
        hash[head[index]] = value.text
      end
      arr << hash
    end
    arr
  end
end
