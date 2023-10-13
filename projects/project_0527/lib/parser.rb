require_relative 'scraper'

class Parser < Hamster::Parser
  COLORS = {
    '#e62117' => 'Red',
    '#cc0022' => 'Scarlet',
    '#cc4e10' => 'Orange',
    '#00824B' => 'Green',
    '#ffffff' => 'White',
    '#222222' => 'Black',
    '#c8880a' => 'Gold',
    '#754Acc' => 'Purple',
    '#034cb2' => 'Blue',
    '#1580a5' => 'Light Blue', #Powder Blue, Sky Blue
    '#022c66' => 'Royal Blue', #Columbia Blue, Dark Blue, Midnight Blue, Navy
    '#046dff' => 'Carolina Blue',
    '#737272' => 'Navy Blue'}

  def initialize(**page)
    super
    @html = Nokogiri::HTML(page[:html])
  end

  def parse_states
    states = html.css('select.form-control option').map do |option|
      { short_name: option['value'].downcase, name: option.text } if option['value'].size == 2
    end
    states.compact
  end

  def parse_schools_links
    html.css('ul.results-list li.result div a.school-link').map { |a| a['href'] }
    .select { |i| i.match?(/https:\/\/www.maxpreps.com/) }
  end

  def parse_school(keeper)
    link = html.at('link[rel="canonical"]')['href']
    Hamster.logger.debug link.green
    name        = html.css('h1.header-text').text
    school      = { name: name, data_source_url: link }
    description = html.css("dl").children
    description.each_with_index do |value, idx|
      if value.text == 'Address'
        address = description[idx + 1]&.text
        if !address.nil? || !address.strip.empty?
          scraper = Scraper.new(keeper)
          gmap_page = scraper.return_gmap_page(description[idx + 1].at('a')['href'])
          raw_coordinates = Nokogiri::HTML(gmap_page).at('meta[itemprop="image"]')['content']
                                                     .sub(/http.+center=/,'').sub(/&zoom.+/,'')
          latitude  = raw_coordinates.match(/^[-|\d]{2,4}\.\d{2,8}/).to_s
          longitude = raw_coordinates.match(/[-|\d]{2,4}\.\d{2,8}$/).to_s
          school[:latitude]  = latitude
          school[:longitude] = longitude
          school[:address]   = address
          parsed_address = parse_address(address)
          school.merge!(parsed_address) if parsed_address
        end
      elsif value.text == 'Mascot'
        school[:mascot] = description[idx + 1].text
      elsif value.text == 'Colors'
        school[:colors] = parse_color(description[idx + 1])
      elsif value.text == 'School Type'
        school[:school_type] = description[idx + 1].text
      elsif value.text == 'Athletic Director'
        director = description[idx + 1] && description[idx + 1].text.size > 5 ? description[idx + 1].text : nil
        school[:director] = director
      elsif value.text == 'Phone'
        school[:phone] = description[idx + 1].text
      end
    end
    school
  end

  private

  attr_reader :html

  def parse_color(tags)
    colors = tags.css('span.color').map do |i|
      if i.text.present?
        i.text
      else
        color_hex = i.at('span').to_html.scan(/background-color:\s*(#\w{1,6})["\s,]/).flatten.first
        COLORS[color_hex.downcase] ? COLORS[color_hex.downcase] : color_hex
      end
    end
    colors = colors.join('|')
    colors.blank? ? nil : colors
  end

  def parse_address(address)
    address_split = address.split(',')
    address_tag   = [:address2, :city, :state, :zip]
    if address_split.size == 4
      if address_split[2].match?(/[A-Z]{2}/) && address_split[3].match?(/(\d+-\d+|\d+)/)
        prepare_address(address_split, address_tag)
      elsif address_split[3].match?(/[A-Z]{2}/)
        address_split = [address_split[0..1].join] + address_split[2..3]
        prepare_address(address_split, address_tag[0..2])
      end
    elsif address_split.size == 3
      if address_split[1].match?(/[A-Z]{2}/) && address_split[2].match?(/(\d+-\d+|\d+)/)
        prepare_address(address_split, address_tag[1..3])
      elsif address_split[2].match?(/[A-Z]{2}/)
        prepare_address(address_split, address_tag[0..2])
      end
    elsif address_split.size == 2
      if address_split.last.match?(/[A-Z]{2}/)
        prepare_address(address_split, address_tag[1..2])
      elsif address_split.last.match?(/(\d+-\d+|\d+)/)
        prepare_address(address_split, address_tag[2..3])
      end
    elsif address_split.size == 1
      if address_split.last.match?(/[A-Z]{2}/)
        prepare_address(address_split, address_tag[3..3])
      end
    elsif address_split.size == 5
      address_split = [address_split[0..1].join] + address_split[2..4]
      prepare_address(address_split, address_tag)
    elsif address_split.size == 6
      address_split = [address_split[0..2].join] + address_split[3..5]
      prepare_address(address_split, address_tag)
    end
  end

  def prepare_address(raw_address, address_tag)
    parsed_address = {}
    raw_address.each_with_index { |val, idx| parsed_address[address_tag[idx]] = val.strip }
    parsed_address
  end
end
