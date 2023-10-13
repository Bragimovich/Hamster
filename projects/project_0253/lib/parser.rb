class Parser < Hamster::Parser

  def get_salary_data(link, run_id)
    document = fetch_nokogiri_response(link)
    salary_info = document.css("tbody")
    data_array = []
    years = get_years(document.css("thead"))
    salary_info.css("tr").each do |row|
      data_hash = {} 
      if  row.css("td.employee").empty?
        data_hash[:full_name]   = data_array.last[:full_name]
        data_hash[:first_name]  = data_array.last[:first_name]
        data_hash[:last_name]   = data_array.last[:last_name]
        data_hash[:middle_name] = data_array.last[:middle_name]
      else
        data_hash[:full_name]   = get_data(row , 'employee')
        data_hash[:first_name], data_hash[:last_name], data_hash[:middle_name] = name_split(data_hash[:full_name])
      end
      data_hash[:employer]         = get_data(row , 'employer')
      data_hash[:job]              = get_data(row , 'position')
      all_salaries = row.css('td.wage').map(&:text).map{|e| e.gsub(',','')}
      all_salaries.each_with_index do |salary, index|
        new_hash = {}
        new_hash           = data_hash.merge(new_hash)
        new_hash[:year]   = years[index]
        new_hash[:salary] = salary
        new_hash[:md5_hash] = create_md5_hash(new_hash)
        new_hash[:run_id]           = run_id
        new_hash[:touched_run_id]   = run_id
        data_array << new_hash
        end
      end
    data_array.reject {|e| e[:salary].nil? or e[:salary].empty? or e[:salary].downcase == 'n/a' or e[:salary].downcase == 'null'}
  end

  def is_next_page(page)
    document = fetch_nokogiri_response(page.body)
    link = document.css("a").select{|a|a.text.include?"next »"}
    link.empty? == false && link.first['href'].empty? == false ? true : false
  end

  private

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def name_split(name)
    last_name,first_name,middle_name = nil
    return [first_name,middle_name,last_name] if name == nil or name == ','
    last_name,first_name = name.split(",")
    if first_name.split(" ").count == 2
      first_name,middle_name = first_name.split(" ")
    else last_name.split(" ").count == 2
      last_name,middle_name = last_name.split(" ")
    end
    [first_name.strip, last_name, middle_name]
  end
  
  def get_years(year_info)
    years = []
    year_info.css("tr a").each_with_index do |row,index|
      next if index < 2
      year = row.text.split(" ").first
      years << year.split("▾").last
    end
    years
  end

  def get_data(row , string)
    return nil if row.css("td.#{string}").empty?
    data = row.css("td.#{string}")[0].text
    data == ','||  data == 'n/a' ? data = nil : data.strip
  end

  def fetch_nokogiri_response(page)
    Nokogiri::HTML(page.force_encoding("utf-8"))
  end
end
