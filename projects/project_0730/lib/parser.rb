class Parser 
  def get_outerpage_links(file_content)
    links = [] 
    parse_page = Nokogiri::HTML(file_content)
    tables = parse_page.css('table.table.table-condensed.table-striped.agency-list')
    tables[2].css('tr').each do |tr|
      tr.css('td:nth-child(2) a').map {|a| links << "https://transparentcalifornia.com"+ a['href']}
    end
    links = links[0..15]
    links = links.reject { |link| link =~ /university-of-california/}
    tables[3].css('tr').each do |tr|
        tr.css('td:nth-child(2) a').map {|a| links << "https://transparentcalifornia.com"+ a['href']}
      end
    links = links[0..170]
    links = links.reject { |link| link =~ /college-redwoods/ || link =~ /college-sequoias/ || link =~ /college-siskiyous/ }
    links.uniq 
  end

  def add_md5(hash)
    hash['deleted'] = 0
    hash['md5_hash'] = Digest::MD5.hexdigest(hash.to_s)
    hash
  end

  def check_pagination(file_content)
    parse_page = Nokogiri::HTML(file_content)
    div_element = parse_page.css('div.pagination.pagination-centered')
    li_elements = div_element.css('li')
    second_last_li = li_elements[-2] if li_elements.length >= 2
    second_last_li.text.strip if second_last_li
  end  

  def parse_maintable(file_content,link)
    parse_page = Nokogiri::HTML(file_content)
    xpath = "//*[@id='main-listing']"
    table =  parse_page.xpath(xpath)
    salaries = []
    table.css('tr').drop(1).each do |tr|
      td_elements = tr.css('td')
      name = td_elements.css('td:nth-child(1) a').text.strip 
      job_element = td_elements.css('td:nth-child(2) a')
      job = job_element.first.text.strip.split('<br>').first
      small_element = td_elements.at_css('small.muted')
      institution, year = small_element.text.strip.split(', ')    
      regular_pay = td_elements.css('td:nth-child(3)').text.strip
      overtime_pay = td_elements.css('td:nth-child(4)').text.strip
      other_pay = td_elements.css('td:nth-child(5)').text.strip
      total_pay = td_elements.css('td:nth-child(6)').text.strip
      benefits = td_elements.css('td:nth-child(7)').text.strip
      total_pay_benefits = td_elements.css('td:nth-child(8)').text.strip  
        salary_data = {
            name: name.gsub("I", ''),
            job_title: job,
            institution: institution,
            year: year,
            regular_pay: regular_pay,
            overtime_pay: overtime_pay,
            other_pay: other_pay,
            total_pay: total_pay,
            benefits: benefits,
            total_pay_n_benefits: total_pay_benefits,
            data_source_url: link,
        }
        salaries << salary_data
    end   
    salaries = salaries.map {|hash| add_md5(hash)}  
    salaries
  end    
end