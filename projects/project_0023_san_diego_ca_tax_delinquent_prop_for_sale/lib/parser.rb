# frozen_string_literal: true

class Parser < Hamster::Parser

  def initialize
    super
  end

  def parse_table(html)
    doc = Nokogiri::HTML(html)
    header = doc.css("[bgcolor='#000063']").css('td b')
    header = header[1..7].map { |n| n.text.gsub(/\(.*\)/, '').parameterize.underscore }

    content = []
    doc.css("[bgcolor='#eeeeee']").to_a[0..-3].concat(doc.css("[bgcolor='#cccccc']").to_a)[0..-4].each do |row|
      content << row.css('td').map { |el| el.text.strip }[0..-2]
    end
    content.sort_by! { |el| el[0].to_i }

    get_result(header, content)
  end

  def parse_abbr_table(html)
    doc = Nokogiri::HTML(html)
    abbr_table = doc.search('table').last

    header = Array.new(abbr_table
                         .search('tr')[1]
                         .search('th, td')
                         .to_a[0..1]
                         .map { |el| el.text.strip.parameterize.underscore })
    content = []
    abbr_table.search('tr')[3..-1].each do |tr|
      tr = tr.search('th, td').to_a[0..1]
      content << tr.map { |el| el.text.strip }
    end
    get_result(header, content.delete_if { |n| n.include?(" ") })
  end

  def get_result(header, content)
    result = []
    content.each do |el|
      result << Hash[header.zip el]
    end
    result.map do |hash|
      hash[:md5_hash] = Digest::MD5.hexdigest hash.values.join('')
      hash.transform_keys(&:to_sym)
    end
  end
end
