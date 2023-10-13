require 'roo'

class Parser < Hamster::Parser

  def parse_page(response)
    Nokogiri::HTML(response.force_encoding('UTF-8'))
  end

  def get_links(page)
    page.css("#innerContent ul")[0..1].map{|e| e.css("li a/@href").map{|x| "https://www.benefits.va.gov"+x.text}}.flatten.reject{|e| e.include? '.pdf' or !e.include? '-q'}
  end

  def parse_data(path)
    xsl = Roo::Spreadsheet.open(path)
    sheet = xsl.as_json
  end

  def parse_file(complete_data, run_id, file)
    hash_array = []
    year = get_year(file)
    quarter_no = get_quarter(file)
    complete_data[1..-1].each do |row|
      data_hash = {}
      data_hash[:year] = year
      data_hash[:quarter_no] = quarter_no
      data_hash[:state_code] = row[0]
      data_hash[:total_loans] = row[1].to_i
      data_hash[:avg_loan_amount] = row[2].to_i
      data_hash[:loan_amount_sum] = row[3].to_i
      data_hash[:total_purchase_loans] = row[4].to_i
      data_hash[:total_purchase_loans_percent] = format_percentage(row, 5)
      data_hash[:loan_amount_avg_purchase] = row[6].to_i
      data_hash[:total_loan_amount_purchase] = row[7].to_i
      data_hash[:total_irrl_loans] = row[8].to_i
      data_hash[:total_irrl_loans_percent] = format_percentage(row, 9)
      data_hash[:loan_amount_avg_irrl] = row[10].to_i
      data_hash[:total_loan_amount_irrl] = row[11].to_i
      data_hash[:total_cash_out_loans] = row[12].to_i
      data_hash[:total_cash_out_percent] = format_percentage(row, 13)
      data_hash[:loan_amount_avg_cash_out] = row[14].to_i
      data_hash[:total_loan_amount_cash_out] = row[15].to_i
      data_hash[:run_id] = run_id
      data_hash[:touched_run_id] = run_id
      data_hash[:data_source_url] = "https://www.benefits.va.gov/HOMELOANS/documents/docs/#{file}"
      hash_array << data_hash
    end
    hash_array
  end

  private
  
  def get_year(file)
    file[/\d+/].to_s.size == 2 ? "20#{file[/\d+/].to_i}" : file[/\d+/].to_i
  end

  def get_quarter(file)
    (file.split("-")[1][/\d+/].nil?) ? nil : file.split("-")[1][/\d+/].to_i
  end

  def format_percentage(row, index)
    (row[index].to_f * 100).round(2)
  end
end
