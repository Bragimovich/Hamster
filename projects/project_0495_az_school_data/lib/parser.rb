# frozen_string_literal: true

class Parser < Hamster::Parser
  
  def get_enrollment_links(response)
    page = parse_page(response)
    page.xpath("//a[contains(text(), 'School Year')][contains(@href, '.xlsx')]").map { |element| {href: element[:href], text: element.text.strip} }.uniq
  end

  def get_assessment_links(response)
    page = parse_page(response)
    page.xpath("//a[contains(text(), 'ssessments')][contains(@href, '.xlsx')]").map { |element| {href: element[:href], text: element.text.strip} }.uniq
  end

  def get_dropout_links(response)
    page = parse_page(response)
    page.xpath("//a[contains(text(), 'Dropout Rates')][contains(@href, '.xlsx')]").map { |element| {href: element[:href], text: element.text.strip} }.uniq
  end

  def get_cohort_links(response)
    page = parse_page(response)
    page.xpath("//a[contains(text(), 'Graduation Rate')][contains(@href, '.xlsx')]").map { |element| {href: element[:href], text: element.text.strip} }.uniq    
  end

  def parse_page(response)
    Nokogiri::HTML(response)
  end

  def get_xlsx_filename_underscored(xlsx_link_text)
    file_name = xlsx_link_text.split(/\p{Space}/).join('_').strip
    file_name = file_name + '.xlsx' unless file_name.include?('.xlsx')
    file_name = file_name.downcase.gsub('-', '_').gsub(/^ssessments/, 'assessments')
  end

  def get_full_xlsx_url(xlsx_href)
    full_url = xlsx_href     
    full_url = Manager::BASE_URL + full_url unless full_url.include?('http')
    if full_url.include?('view.officeapps.live.com') && full_url.include?('www.azed.gov')
      full_url = URI.decode_www_form(full_url)[0][1]
    end
    full_url
  end

end
