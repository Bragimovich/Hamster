# frozen_string_literal: true

require_relative 'keeper'

class Parser < Hamster::Parser

  def parse_req_ver_token(html)
    doc = Nokogiri::HTML html
    doc.at('input[@name="__RequestVerificationToken"]')['value']
  end

  def parse_csv_file_link(html)
    doc = Nokogiri::HTML(html)
    doc.xpath('//*[@id="results-article"]/div/p[4]/a').first.attributes['onclick'].value.gsub("corpExportClick('", "").gsub("');", '').gsub('|', '%7C')
  end

  def csv_records_not_found?(html)
    doc = Nokogiri::HTML(html)
    doc.xpath('//*[@id="results-article"]/div/p[2]').children.text.include?('No records found')
  end

end
