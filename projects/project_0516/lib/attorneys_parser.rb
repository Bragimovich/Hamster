# frozen_string_literal: true

class AttorneysParser < Hamster::Parser
  def initialize(lines)
    super
    @lines              = lines
    @name_index         = lines[2].include?(' [') ? 2 : 1
    @zip_index          = lines.find_index {|el| el =~ /.*, [A-Z]{2} \d{5,}/} ||
                          (lines.find_index {|el| el =~ /^\(\d{3}\) \d{3}-\d{4}$/} || lines.size.pred).pred # city, ST zip..
    @postal_box_index   = lines.rindex {|el| el.include?('Box ')}
    @email_index        = lines.rindex {|el| el.include?('@')}
    @law_firm_index     = find_law_firm_index
    @address_index      = find_address_index
    @address            = lines[@address_index..@zip_index]
    @after_names_index  = @law_firm_index ||
                          (@email_index.nil? ? @postal_box_index || @address_index : @email_index.next)
  end

  def find_law_firm_index
    law_firm_index = @lines[..@zip_index.pred].rindex {|el| el.eql?(el.upcase)}
    law_firm_index -= 1 if @lines[law_firm_index.to_i][0].eql?('#')
    law_firm_index = nil if law_firm_index.to_i <= @email_index.to_i
    return law_firm_index
  end

  def find_address_index
    address_index = @law_firm_index || @email_index
    address_index += 1 unless address_index.nil?
    address_index = (@postal_box_index || @zip_index).pred if address_index.nil?
    return address_index
  end

  def parse
    attorneys = get_attorneys(@lines[1..@after_names_index.pred])
    attorneys.map do |attorney|
    {
      party_name:         attorney[:name],
      party_type:         @lines[0].split(' - ').first,
      party_description:  attorney[:desc],
      party_address:      @address.join("\n"),
      party_city:         @lines[@zip_index].split(',').first,
      party_state:        @lines[@zip_index].split[-2],
      party_zip:          @lines[@zip_index].split.last,
      party_law_firm:     @law_firm_index.nil? ? nil : @lines[@law_firm_index],
      is_lawyer:          1}
    end
  end

  def get_attorneys(names_lines)
    # names_lines.each {|line| logger.debug(line)}
    names = []
    names << one_line_name_desc(names_lines) if names_lines.size.eql?(1)
    names << two_lines_name_desc(names_lines) if names_lines.size.eql?(2)
    names << three_lines_name_desc(names_lines) if names_lines.size.eql?(3)
    names << four_lines_name_desc(names_lines) if names_lines.size.eql?(4)
    names << multiple_attorneys(names_lines) if names_lines.size > 4
    names.flatten
  end

  def one_line_name_desc(lines)
    split = lines.first.split(' [')
    {
      name: split[0],
      desc: split.size.eql?(1) ? "" : split[-1].split(']').first
    }
  end

  def two_lines_name_desc(lines)
    name_with_desc = one_line_name_desc(lines)
    name_with_desc[:desc] += "\n#{lines[1]}" unless lines[1].include?('@') ||
                                                    lines[1].include?('Correctional') ||
                                                    lines[1].include?('Prison') ||
                                                    lines[1] =~ /\d/
    name_with_desc
  end

  def three_lines_name_desc(lines)
    two_lines_name_desc(lines)
  end

  def four_lines_name_desc(lines)
    return multiple_attorneys(lines) if lines.join.count('@') > 1
    lines.shift if lines.last.include?('@')
    three_lines_name_desc(lines)
  end

  # !!!======================== recurrent method ========================!!!
  def multiple_attorneys(lines)
    first_email_index = lines[..-2].find_index {|el| el.include?('@')}
    last_mr_ms_index = lines.rindex {|el| el.start_with?(/\[?(Mr. |Ms.|Mrs.)/)}

    split_index = first_email_index || last_mr_ms_index.pred
    get_attorneys(lines[..split_index]) + get_attorneys(lines[split_index.next..])
  rescue
    return {name: 'can not parse this attorney section', desc: lines.join("\n")}
  end
end
