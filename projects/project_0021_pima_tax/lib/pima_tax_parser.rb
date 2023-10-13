# frozen_string_literal: true

class PimaTaxParser < Hamster::Parser
  def initialize(document = nil)
    super
    @document = Nokogiri::HTML(document)
  end
  
  def has_records?
    @document.css('#warning_content').empty?
  end
  
  def records
    @document.css('#tblPropSearch').css('tr').map do |tr|
      tr.css('td').last.text.strip
    end
  end
  
  def has_table?
    !table.empty?
  end
  
  def table
    @document.css('#tblAcctBal').inner_html
  end

  def property_details
    @document.css('#propertyDetails').inner_html
  end
  
  def parsed_page
    details = []
    parsed_rows.each do |row|
      table_row = {}
      parsed_header.each_with_index do |th, index|
        table_row[th] = row[index]
      end
      details << parsed_details.merge(table_row)
    end
    
    details
  end

  private
  
  def parsed_header
    @document.css('thead tr th').map do |th|
      Nokogiri::HTML(th.inner_html.gsub(%r{<\s?br\s?/?\s?>}i, ' ')).text.strip.downcase.squeeze(' ').split(' ').join('_')
    end[1..-1]
  end
  
  def parsed_rows
    @document.css('tbody tr').map do |tr|
      tr.css('td').map do |td|
        Nokogiri::HTML(td.inner_html.gsub(%r{<\s?br\s?/?\s?>}i, ' ')).text.strip.downcase.squeeze(' ')
      end[1..-1]
    end
  end
  
  def parsed_details
    details = {}
    @document.css('.row.container-fluid .card-body').each do |body|
      title = body.css('h6').text.gsub(%r{\?}, '').squeeze(' ').strip.downcase.split(' ').join('_')
      
      next if title.empty?
      
      if title == 'taxpayer_name/address'
        content = body.css('p').inner_html.split('<br>').map(&:strip)
        details['taxpayer_name'] = content.shift unless content.empty?
        details['taxpayer_address'] = content.shift unless content.empty?
        details['taxpayer_city_state_zip'] = content.shift unless content.empty?
      else
        content = body.css('p').text
        details[title] = content.squeeze("\s").gsub(%r{\r}, '').squeeze("\s\n").gsub(%r{\n\s}, "\n").strip
      end
    end
    
    details
  end
  
end
