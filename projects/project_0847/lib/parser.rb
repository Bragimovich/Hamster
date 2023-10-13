# frozen_string_literal: true
class Parser < Hamster::Parser 
  
  def get_links(file_content)
    links = []
    doc = Nokogiri::HTML(file_content)
    doc.css('td a').map { |a| links << "https://inmatesearch.wcsoma.org#{a['href']}" }
    links.uniq
  end
  
  def get_inmate_detail(file_content,url)
    inmate_data = { }
    doc = Nokogiri::HTML(file_content)
    elements = doc.css('dd.col-sm-10')
    last_name = elements[2].text.strip 
    first_name = elements[3].text.strip 
    middle_name = elements[4].text.strip
    middle_name = elements[4].text.strip == "" ? nil : elements[4].text.strip
    birthdate = elements[5].text.strip 
    birthdate = Date.strptime(birthdate, "%m/%d/%Y")
    formatted_date = birthdate.strftime("%Y-%m-%d")
    age = elements[6].text.strip 
    inmate_data = {
      first_name: first_name,
      middle_name: middle_name,
      last_name: last_name,
      birthdate: formatted_date,
      age: age,
      data_source_url: url,
      md5_hash: Digest::MD5.hexdigest(url)
    }    
    inmate_data
  end  

  def get_inmate_num(file_content,url,inmate_id2)
    inmate_data = { }
    doc = Nokogiri::HTML(file_content)
    elements = doc.css('dd.col-sm-10')
    inmate_num = elements[1].text.strip 
    inmate_data = {
      inmate_id: inmate_id2,
      number:   inmate_num,
      data_source_url: url,
      md5_hash: Digest::MD5.hexdigest(url)
    }
    inmate_id2 += 1
    [ inmate_data,  inmate_id2] 
  end  

  def get_holdin_fac(file_content,url,arrest_id)
    inmate_data = { }
    doc = Nokogiri::HTML(file_content)
    elements = doc.css('dd.col-sm-10')
    block = elements[7].text.strip 
    cell = elements[8].text.strip 
    inmate_data = {
      arrest_id: arrest_id,
      block: block,
      cell: cell,
      data_source_url: url,
      md5_hash: Digest::MD5.hexdigest(url)
    }
    arrest_id += 1
    [inmate_data, arrest_id ]
  end

end

