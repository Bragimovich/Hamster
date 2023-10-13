class Parser <  Hamster::Parser

  def main_page_body(response)
    page_scraper = parsing(response.body)
  end

  def next_page(response)
    links = response.css("tfoot th a")
    next_page = links.select{|link| link.text.include? "next" }
    (next_page == []) ? false : ((next_page[0].text.include? "next")? true : false)
  end

  def michigan_government_salaries(each_page_content, run_id, file)
    government_salaries = {}
    year_list = []
    salaries_array = []
    parsed_content = parsing(each_page_content)
    all_rows = parsed_content.css("table tbody tr")
    years = parsed_content.css("table thead th.wage")
    year_list = all_years(years)
    all_rows.each do |each_row|
      full_name = each_row.css("td.employee").text
      full_name, first_name, middle_name, last_name = fetching_full_name(full_name, salaries_array)
      employer = each_row.css("td.employer").text
      job = each_row.css("td.position").text
      all_year_wages = each_row.css("td.wage")
      wage = wages_data(all_year_wages)
      year_wage = Hash[year_list.zip wage]
      year_wage.each do |year, wage|
        salaries_hash = {}
        salaries_hash[:full_name]   =  full_name
        salaries_hash[:first_name]  =  first_name
        salaries_hash[:middle_name] =  middle_name
        salaries_hash[:last_name]   =  last_name
        salaries_hash[:employer]    = employer
        salaries_hash[:job] = job 
        salaries_hash[:year] = year.gsub("▾","")
        salaries_hash[:salary] = wage.gsub(",","")
        salaries_hash[:md5_hash] = create_md5_hash(salaries_hash)
        salaries_hash[:run_id] = run_id
        salaries_hash[:touched_run_id] = run_id
        salaries_hash[:last_scrape_date] = Date.today.to_s
        next_date = Date.today+1.year
        salaries_hash[:next_scrape_date] = next_date.to_s
        salaries_hash[:data_source_url] = "https://www.mackinac.org/salaries?report=any&search=any&filter=&page=#{file.scan(/\d+/).join.to_i}&count=1000#report"
        salaries_array << salaries_hash
      end
    end
    salaries_array
  end

  private

  def parsing(pages)
    Nokogiri::HTML(pages.force_encoding("utf-8"))
  end

  def split_full_name(name)
    if name.squish == ","
      name, first_name, middle_name, last_name = nil
    else
      split_2 = name.split(" ")
      first_name = split_2[0].gsub(",","")
      split_2.shift
      last_name = split_2.last
      split_2.pop
      middle_name = split_2 != [] ? (split_2.count > 2 ? split_2.join(" ") : split_2[0]) : nil
    end
    [name, first_name, middle_name, last_name]
  end

  def fetching_full_name(full_name, salaries_array)
    if full_name.nil? || full_name.empty?
      full_name = salaries_array.last[:full_name]
      full_name, first_name, middle_name, last_name = split_full_name(salaries_array.last[:full_name])
    else
      full_name, first_name, middle_name, last_name = split_full_name(full_name) unless full_name.empty? || full_name.nil?
    end
    [full_name, first_name, middle_name, last_name]
  end

  def all_years(years)
    year_list = []
    years.each do |each_year|
      year_list << each_year.text.split(" ")[0]
    end
    year_list
  end

  def wages_data(all_year_wages)
    wage = []
    all_year_wages.each do |yearwise_wage|
      wage << yearwise_wage.text
    end
    wage
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.each_value do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
