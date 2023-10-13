class Parser

  def get_table_rows(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//table[@class='views-table cols-5']/tbody"
    parsed_page.xpath(xpath)&.css('tr')
  end

  def get_url_from_row(row_div)
    row_div.css('td')[2].children[1]['href']
  end

  def get_total_pages(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//div[@class='oversight-table-summary']"
    parsed_page.xpath(xpath).text.split(' ').last.to_i
  end

  def get_all_reports(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//div[@class='report-details-wrapper']/div"
    parsed_page.xpath(xpath)
  end

  def get_title_from_page(file_content)
    parsed_page = Nokogiri::HTML(file_content)
    xpath = "//h1[@id='page-title']"
    parsed_page.xpath(xpath)&.first&.text
  end

  def parse_all_reports(reports)
    hash = {}
    reports.each do |report|
      title = report.children.first.text
      field = report.children.last.text

      if title.include?('Date Issued')
        hash['report_date'] = field
      
      elsif title.include?('Agency Reviewed')
        hash['agency_reviewed'] = field

      elsif title.include?('Location')
        hash['Location'] = report.children.last

      elsif title.include?('Report Description')
        hash['report_description'] = field
      
      elsif title.include?("Report Number")
        hash['report_number'] = field

      elsif title.include?('Questioned Costs')
        hash['questioned_costs'] = field

      elsif title.include?('Funds for Better Use')
        hash['funds_for_better_use'] = field

      elsif title.include?('Type of Report')
        hash['type'] = field

      elsif title.include?('View Document')
        hash['report_pdf_link'] = report.children.last.css('a')&.first['href']
      
      elsif title.include?('Additional Details Link')
        hash['additional_details_link'] = report.children.last.css('a')&.first['href']
      end
    end
    hash
  end

  def parse_location(location_div)
    locations = location_div&.xpath(".//*[contains(@class,'field-item')]")
    parsed_locations = []

    locations&.each do |location|
      parsed_locations << {
        'location': location&.text,
        'city': location.xpath(".//span[@class='locality']")&.text,
        'state': location.xpath(".//span[@class='state']")&.text,
        'country': location&.text.include?("Agency") ? nil : location.xpath(".//span[@class='country']")&.text
      }
    end
    parsed_locations
  end
end