class Parser < Hamster::Parser
  def initialize
    super
    @count = 0
  end

  def parse_web_date(page)
    document = Nokogiri::HTML(page)
    raw_date = document.css('.average-price').css('span').text.gsub("Price as of", "")
    Date.strptime(raw_date, '%m/%d/%y')
  end

  def parse(file_content, file)
    @state, @date = file.gsub('.gz', '').split("_")
    prices_table  = Nokogiri::HTML(file_content).at('.table-mob')
    prices        = parse_prices(prices_table)
    metro_tables  = Nokogiri::HTML(file_content).at('.accordion-prices')

    return { prices: prices, metro_areas: [] } if metro_tables.nil?

    area_tables = metro_tables.search('.table-mob')
    area_names  = metro_tables.search('h3')
    metro_areas = []
    area_names.zip(area_tables) { |name, table| metro_areas << parse_metro_area(name, table) }
    { prices: prices, metro_areas: metro_areas }
  end

  def parse_prices(table)
    cells = []
    table.search('tr').each do |tr|
      cells << tr.search('td').text.split("$")[1..-1] if tr.search('td').text != ""
    end
    { report_date: @date, state: @state, cells: cells }
  end

  def parse_metro_area(area, table)
    cells = []
    table.search('tr').each do |tr|
      cells << tr.search('td').text.split("$")[1..-1] if tr.search('td').text != ""
    end
    { report_date: @date, state: @state, metro_area: area.children.text, cells: cells }
  end
end
