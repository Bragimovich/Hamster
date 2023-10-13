# frozen_string_literal: true

class Parser < Hamster::Parser
  
  def parse_enrollment(raw_data)
    headers = []
    csv_data = []
    raw_data.each do |row|
      if row[0].downcase == 'school year'
        headers = parse_enrollment_header(row)
        csv_data << headers
        next
      end
      csv_data << row
    end
    csv_data
  end

  def parse_enrollment_header(row)
    headers = []
    row.each do |v|
      if v =~ /School Year/i
        headers << 'school_year'
      elsif v =~ /Level/i
        headers << 'level'
      elsif v =~ /Division Number/i
        headers << 'division_number'
      elsif v =~ /Division Name/i
        headers << 'division_name'
      elsif v =~ /School Number/i
        headers << 'school_number'
      elsif v =~ /School Name/i
        headers << 'school_name'
      elsif v =~ /Full Time Count/i
        headers << 'full_time_count'
      elsif v =~ /Part Time Count/i
        headers << 'part_time_count'
      elsif v =~ /Total Count/i
        headers << 'total_count'
      end
    end
    headers
  end

  def parse_finances_receipts_headers(row)
    hash_headers = {}
    row.each_with_index do |v, i|
      if v =~ /Division Number/i
        hash_headers['div_num'] = i
      elsif v =~ /School Division/i || v =~ /Division\/Regional Program/i
        hash_headers['div_name'] = i
      elsif v =~ /School Division/i
        hash_headers['school_div'] = i
      elsif v =~ /State Sales/i || v =~ /From Sales and Use Tax/i
        hash_headers['state_sales'] = i
      elsif v =~ /State Funds/i
        hash_headers['state_funds'] = i
      elsif v =~ /Federal Funds/i
        hash_headers['federal_funds'] = i
      elsif v =~ /County Funds/i
        hash_headers['local_funds'] = i
      elsif v =~ /Other Funds/i
        hash_headers['other_funds'] = i
      elsif v =~ /Loans/i && v =~ /Bonds/i
        hash_headers['loan_bonds'] = i
      elsif v == 'Total Receipts'
        hash_headers['total_receipts'] = i
      elsif v =~ /Balances at Beginning/i
        hash_headers['balances_bg_year'] = i
      elsif v =~ /Total Receipts and Balances/i
        hash_headers['balances_receipts'] = i
      end
    end
    hash_headers
  end

end
