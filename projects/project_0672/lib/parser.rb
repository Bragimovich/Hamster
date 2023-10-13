# frozen_string_literal: true

class Parser < Hamster::Parser

  def pdf_parsing(pages)
    data_array = []
    agency = ""
    pages.each_with_index do |page, ind|
      charge_flag = false
      data_hash = {}
      page.text.scan(/^.+/).map do |row|
        next if row == ''
        agency_row = row.scan(/\w.*JCSO/)
        unless agency_row.empty?
          agency = agency_row.first.gsub("JCSO","").strip
          next
        end
        check_data_row = row.scan(/[A-Z].\d{5}\s*\d{2}\/\d{2}/)
        next if check_data_row.empty? and !charge_flag

        if charge_flag 
          # charge_flag is to to handle when charge found in next row insead of data row
          charge_flag = false
          if check_data_row.empty?
            data_hash['charge'] = row.strip
            charge_flag = false
            data_array.push(data_hash)
            next
          else  
            data_hash['charge'] = nil
            data_array.push(data_hash)
          end
        end

        date = row.scan(/\d*\/\d*\/\d*/).first
        date_split = row.split(date)
        arrest_id = date_split.first.strip

        date_split_2nd = date_split.last
        sex_race =  date_split_2nd.strip.scan(/\s[A-Z]{1}\s+[A-Z]{1}$/)
        sex = []
        sex = date_split_2nd.strip.scan(/\s[A-Z]{1}$/) if sex_race.empty?
        last_part = ''
        last_part = sex_race.first.strip unless sex_race.empty?
        last_part = sex.last.strip unless sex.empty?
        sex_race_array = last_part.split(' ')
        charge_name = date_split_2nd
    
        charge_name = charge_name.split(last_part)[0..-1].join("") if last_part.length > 0
        
        charge_name_split = []
        (2..20).to_a.reverse.each do |e|
          next if e == 3
          charge_name_split = charge_name.split(/\s{#{e},}/)
          break if charge_name_split.count > 1
        end
        charge_flag = true if charge_name_split.first == ''
        charge = charge_name_split.first.strip.split(" ").map{|e| e.strip.squish}.reject{|e| e ==''}.join(" ") rescue '-'
        name = charge_name_split.count > 1 ? charge_name_split[1..-1] : charge_name_split[0..-1]
        name = name.map{|e| e.strip.squish}.reject{|e| e ==''}.join(" ")
        data_hash = {}
        data_hash['agency'] = agency
        data_hash['date_of_arrest'] = DateTime.strptime(date, "%m/%d/%Y").to_date.to_s
        data_hash['arrest_id'] = arrest_id
        data_hash['charge'] = charge
        data_hash['name'] = name
        data_hash['sex'] = sex_race_array[0].strip rescue nil
        data_hash['race'] = sex_race_array[1].strip rescue nil
        data_hash['full_row'] = row
        data_hash['charge_name'] = charge_name
        data_hash['page_no'] = ind + 1

        data_array.push(data_hash) unless charge_flag
      end
      puts "Processing Page No #{ind}"
    end
    data_array
  end
end
