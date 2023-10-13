# frozen_string_literal: true

class Parser < Hamster::Parser
  
  def parse_compensation_data(doc)
    data_arr = []
    campus_arr = doc.xpath("//div[@role='gridcell'][@column-index='0']/text()").map(&:text)
    payee_arr = doc.xpath("//div[@role='gridcell'][@column-index='1']/text()").map(&:text)
    position_title_arr = doc.xpath("//div[@role='gridcell'][@column-index='2']/text()").map(&:text)
    amount_paid_arr = doc.xpath("//div[@role='gridcell'][@column-index='3']/text()").map(&:text)
    campus_arr.each_with_index do |campus, index|
      next if campus == 'Total'
      amount_paid = amount_paid_arr[index].strip.gsub(",", "").strip
      if amount_paid.empty?
        amount_paid = nil
      end
      data_arr << {
        campus: clean_str(campus),
        payee: clean_str(payee_arr[index]),
        position_title: clean_str(position_title_arr[index]),
        amount_paid: amount_paid,
        data_type: 'compensation'
      }
    end
    data_arr
  end

  def clean_str(str)
    new_str = str.strip.gsub(/\p{Zs}/, " ")
    return nil if new_str == ''
    new_str
  end

  def parse_expenditures_data(doc)
    data_arr = []
    campus_arr = doc.xpath("//div[@role='gridcell'][@column-index='0']/text()").map(&:text)
    payee_arr = doc.xpath("//div[@role='gridcell'][@column-index='1']/text()").map(&:text)
    amount_paid_arr = doc.xpath("//div[@role='gridcell'][@column-index='2']/text()").map(&:text).map{|e| e.gsub(",", "").strip}
    campus_arr.each_with_index do |campus, index|
      next if campus == 'Total'
      amount_paid = amount_paid_arr[index]
      amount_paid = nil if amount_paid.empty?
      data_arr << {
        campus: campus,
        payee: payee_arr[index],
        amount_paid: amount_paid,
        data_type: 'expenditures'
      }
    end
    data_arr
  end

end
