class Parser < Hamster::Parser
  def check_next(html)
    document = Nokogiri::HTML(html.body.force_encoding("utf-8"))
    count = document.css('form div table tr td')[1].text
    (count.include? 'Next')? false : true
  end

  def get_inner_links(html)
    document = Nokogiri::HTML(html.force_encoding("utf-8"))
    document.css('table.FormTable')[1].css('tr').css('td a').map{|a| a['href']}.select{|link| link.include? 'csNameID='}.uniq
  end

  def get_parsed_document(submit_page)
    Nokogiri::HTML(submit_page)
  end

  def get_data_site_key(document)
    document.css('div.g-recaptcha')[0]['data-sitekey']
  end

  def prepare_info_hash(html, index, run_id)
    page = Nokogiri::HTML(html.force_encoding("utf-8"))
    row = get_row(page, index)
    case_id = row.css('td')[0].text
    court = row.css('td')[1].text
    (court.include? 'Supreme')? court_id = 324 : court_id = 440
    case_name = row.css('td')[2].text
    status_as_of_date = row.css('td')[3].text
    case_type = row.css('td')[4].text
    case_description = row.css('td')[5].text
    case_filed_date = date_conversion(row.css('td')[6].text)
    link = row.css('td a')[0]['href']
    data_hash = {
      court_id: court_id,
      case_id: case_id,
      case_name:  case_name,
      case_type: case_type,
      status_as_of_date: status_as_of_date,
      case_description: case_description,
      data_source_url: "https://macsnc.courts.state.mn.us#{link}",
      case_filed_date: case_filed_date
    }
    data_hash = mark_empty_as_nil(data_hash)
    data_hash[:md5_hash] = create_md5_hash(data_hash)
    data_hash[:run_id] = run_id
    @basic_details = [case_id, court_id, link]
    data_hash
  end

  def get_case_activities(html, already_inserted_pdfs, run_id)
    activites_array = []
    page = Nokogiri::HTML(html.force_encoding("utf-8"))
    case_id, court_id, link= @basic_details
    table = page.css('table[class="FormTable"]').select{|e| e.text.include? 'Docket Information'}
    return [] if table.count == 0
    table = table.first.css('tr').reject{|a| (a['class'] ==  'TableSubHeading') || (a['class'] == 'TableHeading')}
    count = 0
    downloaded_files = peon.give_list(subfolder: "/PDF")
    table.each do |row|
      court = row.css('td')[1].text.squish
      (court.include? 'Supreme')? court_id = 324 : court_id = 440
      values = row.css('td').last.css('a')[0]['onmouseover'].split("event, ").last.split(',') rescue nil
      pdf_links = downloaded_files.select {|f| f.start_with? values[1].squish rescue nil}
      pdf_links = already_inserted_pdfs.select{|a| a.include? "_#{values[1].to_s.squish}_"}.map{|a| a.split("_#{values[1].to_s.squish}_").last.gsub(".pdf", "")} if ((pdf_links.empty?) && !(values.nil?))
      pdf_links = [] if ((values.nil?) || (pdf_links.empty?))
      pdf_links = pdf_links.map{|a| "https://macsnc.courts.state.mn.us/ctrack/document.do?document=#{a.gsub('.gz','').split('_').last}"}.join("\n")
      data_hash = {
        court_id: court_id,
        case_id: case_id,
        activity_decs: row.css('td')[0].text,
        activity_date: date_conversion(row.css('td')[2].text.squish),
        activity_type: row.css('td')[3].text,
        data_source_url: "https://macsnc.courts.state.mn.us#{link}"
      }
      data_hash[:file] = pdf_links
      data_hash = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = run_id
      activites_array << data_hash
      count+=1
    end
    activites_array
  end

  def get_values(row)
    row.css('td').last.css('a')[0]['onmouseover'].split("event, ").last.split(',') rescue nil
  end

  def get_pdf_table_rows(html)
    page = Nokogiri::HTML(html.force_encoding("utf-8"))
    table = page.css('table[class="FormTable"]').select{|e| e.text.include? 'Docket Information'}
    return [] if table.count == 0
    table = table.first.css('tr').reject{|a| (a['class'] ==  'TableSubHeading') || (a['class'] == 'TableHeading')}
  end

  def get_indexed_html(html)
    index_no = html.index('<span id="partyTable"')
    html = html[index_no..-1]
    index_no = html.index('<input type="hidden" name="csNameID"')
    return {} if index_no == nil
    html[0..index_no+6].force_encoding("utf-8")
  end

  def get_case_parties(html, run_id)
    party_array = []
    html = get_indexed_html(html).gsub("</br", "<br/")
    page = Nokogiri::HTML(html.force_encoding("utf-8"))
    table = get_table(page, 'partyTable')
    return [] if table.count == 0
    table.delete_at(0) if table[0].text.include? "Jurisdiction:"
    table.each do |row|
      (0..1).each do |is_lawyer|
        party_array.concat(get_attorney_data(row, is_lawyer, run_id))
      end
    end
    party_array.reject{|a| a[:party_name].empty?}
  end

  def get_aws_hash(html, activites_array, run_id, s3)
    aws_array = []
    pdfs = activites_array.select{|a| a[:file].to_s.length > "https://macsnc.courts.state.mn.us/ctrack/document.do?document=".length}
    links = pdfs.map{|a| a[:file].split(" ")}.flatten
    pdfs = links.map{|a| a.split("document=").last}.flatten
    case_id, court_id, link = @basic_details
    downloaded_files = peon.give_list(subfolder: "/PDF")
    html_key = "us_courts_expansion_#{court_id}_#{case_id}_info.html"
    aws_html_link = s3.put_file(html, html_key, metadata={})
    pdfs.each_with_index do |name, ind|
      file_name = downloaded_files.select {|f| f.end_with? "#{name.squish}.gz" rescue nil}.first rescue nil
      next if file_name.nil?
      file = peon.give(subfolder: "/PDF", file: file_name)
      key = "us_courts_expansion_#{court_id}_#{file_name.gsub('.gz','')}.pdf"
      data_hash = {
        court_id: court_id,
        case_id: case_id,
        source_type: 'Activity',
        aws_html_link: aws_html_link,
        aws_link: upload_on_aws(s3, file, key),
        source_link: links[ind],
        data_source_url: "https://macsnc.courts.state.mn.us#{link}"
      }
      data_hash = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = run_id
      aws_array << data_hash
    end
    aws_array
  end

  def get_activity_relations(activites_array, aws_array)
    relation_array = []
    links = aws_array.map{|a| a[:source_link]}
    links.each do |link|
      activity_hash = activites_array.select{|a| a[:file].to_s.include? link}[0]
      no_of_links = activity_hash[:file].to_s.split(" ")
      no_of_links.each do |pdf_link|
        aws_hash = aws_array.select{|a| a[:source_link].include? pdf_link}[0]
        data_hash = {
          case_activities_md5: activity_hash[:md5_hash],
          case_pdf_on_aws_md5: aws_hash[:md5_hash]
        }
        relation_array << data_hash
      end
    end
    relation_array.uniq
  end

  private

  def upload_on_aws(s3, file, key)
    url = 'https://court-cases-activities.s3.amazonaws.com/'
    return "#{url}#{key}" unless s3.find_files_in_s3(key).empty?
    s3.put_file(file, key, metadata={})
  end

  def get_attorney_data(row, is_lawyer, run_id)
    case_id, court_id, link = @basic_details
    party_names = []
    party_array = []
    if is_lawyer == 0
      party_names <<  row.css('td')[2].text
      type = row.css('td')[1].text
      firm = nil
    else
      party_names = row.css('td')[3].children.reject{|a| a.text.empty?}
      type = "#{row.css('td')[1].text} Attorney"
    end
    party_names.each do |party|
      data_hash = {
        court_id: court_id,
        case_id: case_id,
        party_name: party,
        party_law_firm: firm,
        party_type: type,
        party_description: row.css('td')[0].text,
        is_lawyer: is_lawyer,
        data_source_url: "https://macsnc.courts.state.mn.us#{link}"
      }
      data_hash = mark_empty_as_nil(data_hash)
      data_hash[:md5_hash] = create_md5_hash(data_hash)
      data_hash[:run_id] = run_id
      party_array << data_hash
    end
    party_array
  end

  def get_table(page, tag)
    page.css("##{tag} tr").reject{|a| (a['class'].include? 'TableSubheading') || (a['class'].include? 'TableHeading')}
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    md5_hash = Digest::MD5.hexdigest data_string
  end

  def date_conversion(value)
    DateTime.strptime(value, '%m/%d/%Y').to_date rescue nil
  end

  def get_row(page, index)
    page.css('table.FormTable')[1].css('tr')[index]
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| value.to_s.empty? ? nil : ((value.to_s.valid_encoding?)? value.to_s.squish : value.to_s.encode("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '').squish)}
  end
end
