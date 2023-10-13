# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize(doc)
    @html = Nokogiri::HTML doc
  end

  def offender_list
    list_arr = []
    list = @html.css("a[href='#']").map {|el| el.attr("id")}
    list.each do |row|
      if row.include?('viewFlyerLink')
        list_arr << row
      end
    end
    list_arr
  end

  def check_session
    raise "Page Session expired" if @html.css("span[class='ui-panel-title']").text.include?("Page Session expired")
  end

  def parse_offender
    date_of_mage =  @html.css('.Container40')[0].css('span').last.text.split('/')
    date = Date.parse((date_of_mage[2] + date_of_mage[0] + date_of_mage[1])).strftime("%Y-%m-%d") rescue nil
    birth =  @html.css('.Container40')[5].text.strip.split('/')
    birthdate = Date.parse((birth[2] + birth[0] + birth[1])).strftime("%Y-%m-%d")

    {
      original_link: "https://offender.fdle.state.fl.us#{@html.css('img').first.attr("src")}",
      date: date,
      designation: @html.css('.Container40')[1].text.strip,
      full_name: @html.css('.Container40')[2].text.strip,
      status: @html.css('.Container40')[3].text.strip,
      dept_of_corrections: @html.css('.Container40')[4].css('a').map{|el| el.text}.join,
      birthdate: birthdate,
      age: Time.now.strftime("%Y").to_i - birth.last.to_i,
      race: @html.css('.Container40')[6].text.strip,
      sex: @html.css('.Container40')[7].text.strip,
      hair_color: @html.css('.Container40')[8].text.strip,
      eye_color: @html.css('.Container40')[9].text.strip,
      height: @html.css('.Container40')[10].text.strip.gsub("\"",""),
      weight: @html.css('.Container40')[11].text.gsub("lbs", "").strip,
      aliases: @html.css(".ui-accordion-content")[0].text,
      tattoo: offender_tattoo,
      address: offender_address,
      crime_info: offender_crime,
      victim_info: offender_victim_info,
      vehicle_info: offender_vehicle_info,
      vessel_info: offender_vessel_info
    }
  end
 

  def offender_tattoo
    tattoo_arr = Array.new
    head = [:type_marks, :body_location, :smt_count]
    @html.css(".ui-accordion-content")[1].css("tbody").css('tr').each do |value|
      hash = Hash.new
      value.css('td').each_with_index do |row, index|
        hash[head[index]] = row.text
      end
      tattoo_arr << hash
    end
    tattoo_arr
  end

  def offender_address
    address_arr = Array.new
    head = [:full_address, :source_information]
    @html.css(".ui-accordion-content")[2].css("tbody").css('tr').each do |value|
      hash = Hash.new
      value.css('td').each_with_index do |row, index|
        if index == 0
          raw_address = row.css('span').map {|el| el.text}[-2].match(/((?:[A-Za-z]+\s?.?)+)?,\s?([A-Z]{2})?\s(\d{5}-?\d{4}?)?/) rescue nil
          hash[:city] = raw_address[1] rescue nil
          hash[:state] = raw_address[2] rescue nil
          hash[:zip] = raw_address[3] rescue nil
        end
        hash[head[index]] = row.css('span').map {|el| el.text}.join("; ")
      end
      address_arr << hash
    end
    address_arr
  end

  def offender_crime
    crime_info_arr = Array.new
    head = [:date, :description, :case_number, :jurisdiction, :adjudication]
    @html.css(".ui-accordion-content")[3].css("tbody").css('tr').each do |value|
      hash = Hash.new
      value.css('td').each_with_index do |row, index|
        if index == 0
          raw_date = row.text.strip.split('/') rescue nil
          hash[head[index]] = Date.parse((raw_date[2] + raw_date[0] + raw_date[1])).strftime("%Y-%m-%d") rescue nil
        else
          hash[head[index]] = row.text.strip
        end
      end
      crime_info_arr << hash
    end
    crime_info_arr
  end

  def offender_victim_info
    victim_info_arr = Array.new
    head = [:gender, :minor]
    @html.css(".ui-accordion-content")[4].css("tbody").css('tr').each do |value|
      hash = Hash.new
      value.css('td').each_with_index do |row, index|
        hash[head[index]] = row.text.strip
      end
      victim_info_arr << hash
    end
    victim_info_arr
  end

  def offender_vehicle_info
    vehicle_info_arr = Array.new
    head = [:make, :type_vehicles, :color, :year, :body, :registration]
    @html.css(".ui-accordion-content")[5].css("tbody").css('tr').each do |value|
      hash = Hash.new
      value.css('td').each_with_index do |row, index|
        hash[head[index]] = row.text.strip
      end
      vehicle_info_arr << hash
    end
    vehicle_info_arr
  end

  def offender_vessel_info
    vessel_info_arr = Array.new
    head = [:make, :vessel_type, :color, :motor_type, :hull_material, :year, :registration ]
    @html.css(".ui-accordion-content")[6].css("tbody").css('tr').each do |value|
      hash = Hash.new
      value.css('td').each_with_index do |row, index|
        hash[head[index]] = row.text.strip
      end
      vessel_info_arr << hash
    end
    vessel_info_arr
  end
end
