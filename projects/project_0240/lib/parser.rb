require 'roo-xls'

class Lawyer_Parser < Hamster::Parser

  def parsing(response)
    all_links = []
    link_mnth = []
    page = Nokogiri::HTML(response.body)
    page.css("div a").each{|txt| all_links << txt}
    all_links.each do |link|
      if link["href"].include?"/voterstats-#{Date.today.year}" or link["href"].include?"/voterstats-#{Date.today.next_year.to_s.split('-').first}01"
        hash_data = find_month_element(link)
        link_mnth << hash_data
      end
    end
    link_mnth
  end

  def parsing_xlsx(file_path, file_name, run_id)
    data = []
    current_year = Date.today.year.to_s
    if file_name.include? current_year or ((file_name.include? "#{Date.today.next_year.to_s.split('-').first}01") and (!file_name.include? "#{current_year}01"))
      year = current_year
    elsif (file_name.include? "#{Date.today.year}01") or ((file_name.include? "#{Date.today.prev_year.to_s.split('-').first}01") and (!file_name.include? "#{Date.today.prev_year.to_s.split('-')}01"))
      year = "#{Date.today.prev_year.to_s.split('-').first}"
    end  
    

    url = file_name[11, 15]
    month = file_name.split('-').last.split('.').first
    xlsx_file = Roo::Excel.new(file_path)
    sheet_name = xlsx_file.sheets[0]
    xlsx_file.sheet(sheet_name).each do |row|
      next if row.include?"County" or row[0].nil? or row.include?"Statewide totals"
      final = Hash.new
      final["year"] = year
      final["month"] = month
      final["county"] = row[0]
      final["precinct"] = row[1].to_i
      final["democratic"] = row[2].to_i
      final["republican"] = row[3].to_i
      final["other"] = row[4].to_i
      final["ind"] = row[5].to_i
      final["libert"] = row[6].to_i
      final["green"] = row[7].to_i
      final["const"] = row[8].to_i
      final["reform"] = row[9].to_i
      final["soc_wk"] = row[10].to_i
      final["male"] = row[11].to_i
      final["female"] = row[12].to_i
      final["registered"] = row[13].to_i
      final["data_source_url"] = "https://elect.ky.gov/Resources/Documents/voterstats-#{url}.xls"
      final["run_id"] = run_id
      final["last_scrape_date"]= Date.today
      final["next_scrape_date"]= Date.today.next_month
      data << final
    end
    data
  end

  private

  def find_month_element(link)
    link_to_month_element = link.parent.parent.previous_sibling
    if link_to_month_element.nil?
      link_to_month_element = link.parent.parent.parent.previous_sibling.text.split
    elsif link_to_month_element.text.include?"The voter registration"
      link_to_month_element = link.parent.previous_sibling.text.split
    else
      link_to_month_element.text.include?"By Congressional Senate" ? link_to_month_element = link_to_month_element.text.split('By Congressional Senate, House, and Supreme Court').last : link_to_month_element = link_to_month_element.text.split
    end
    month_link_into_hash(link_to_month_element, link)
  end
  
  def month_link_into_hash(link_to_month_element, link)
    link_to_month_element.respond_to?(:to_a) ? month = link_to_month_element.join(' ') : month = link_to_month_element
    mnth_link = Hash.new
    mnth_link["link"] = link["href"]
    mnth_link["month"] = month
    mnth_link
  end

end
