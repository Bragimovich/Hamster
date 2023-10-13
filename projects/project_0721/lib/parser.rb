# frozen_string_literal: true

require_relative 'pdf_parser'
class Parser < Hamster::Parser
  def pdf_urls_from(response_body)
    pdf_url_data = []
    parsed_doc = Nokogiri::HTML.parse(response_body)
    pdf_file_links = parsed_doc.xpath("//ul[@class='submenu js-submenu']/li/a[@href]")
    pdf_file_links.each do |link|
      pdf_url_data << {
        name: link.children.text,
        url: link.attributes['href'].value
      }
    end
    pdf_url_data
  end

  def process_pdf(pdf_url_data)
    hash_data   = []
    match       = pdf_url_data[:name].match(/quarter\s(\d)\s\((\d{4})\)/i)
    pdf_url     = pdf_url_data[:url]
    pdf_parser  = PdfParser.new(pdf_url)
    table_data  = pdf_parser.get_table_data()
    started     = false
    col_count   = 0
    table_data.each do |data|
      if started == false && data[0].match(/District\/Charter/)
        started = true
        col_count = data.count
      end

      next unless started
      next unless data.count == col_count

      data.unshift(nil) unless data.count == 3

      next if data[2].nil?
      next if data[2].length > 10

      # change hex code to string
      district_name = data[1].force_encoding('iso-8859-1').encode('utf-8') rescue data[1]
      district_name.gsub!(/\u0000±/, '-')
      hash_data << {
        quarter: match[1].to_i,
        year: match[2].to_i,
        district_id: data[0],
        district_name: district_name,
        students_count: data[2],
        data_source_url: pdf_url
      }
    end
    hash_data
  end
end
