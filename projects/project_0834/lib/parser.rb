# frozen_string_literal: true

class Parser < Hamster::Parser
  def initialize(doc)
    super
    @html = Nokogiri::HTML doc
    @logger.debug(doc)
  end

  def parse_inmate
    {
      full_name: parse_info(1).strip,
      number: parse_info(3),
      birthdate: parse_birthdate(parse_info(5)),
      race: parse_info(7),
      sex: parse_info(9),
      age: age(parse_info(5)),
      arrest_date: parse_date(parse_info(11)),
      intake_time: parse_info(13),
      magistration_time: parse_info(15),
      disposition: parse_info(17),
      magistrate_release_date: parse_date(parse_info(19)),
      comments: parse_info(21),
      data_table: parse_table
    }
  end

  def parse_info(num)
    @html.css("div[class='column2']").children[num].text
  end

  def parse_table
    head = [ :number, :crime_class, :offense_type, :bond_amount ]
    arr = []
    @html.css("table[id='bcitDataTable']").css('tbody').css('tr').each do |row|
      hash = {}
      row.css('td').each_with_index do |value, index|
        hash[head[index]] = value.text.strip
      end
      arr << hash
    end
    arr
  end

  def age(date)
    now = Time.now.utc.to_date
    birthdate = Date.parse(date)
    now.year - birthdate.year - ((now.month > birthdate.month || (now.month == birthdate.month && now.day >= birthdate.day)) ? 0 : 1)
  end

  def parse_date(date)
    DateTime.parse(date).strftime("%Y-%m-%d %H:%M:%S") rescue nil
  end

  def parse_birthdate(date)
    Date.parse(date).strftime("%Y-%m-%d") rescue nil
  end
end
