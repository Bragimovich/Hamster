# frozen_string_literal: true
require 'roo'

class Parser < Hamster::Parser

  def get_year(file)
    File.basename(file).gsub('.xlsx','').to_i
  end

  def get_data(year, file, run_id, db_md5)
    data_array = []
    md5_array = []
    xlsx_file = Roo::Spreadsheet.open(file) rescue nil
    return [] if xlsx_file.nil?
    sheet_name = xlsx_file.sheets.select { |e| e == 'Sheet 1' }[0]
    return [] if sheet_name.nil?
    
    data_array , headers = [], []
    xlsx_file.sheet(sheet_name).each_with_index do |row, index|
      hash = {}
      if index == 0
        headers = row.drop(1).map { |k| k.gsub(' ', '_').downcase.gsub('max._base', 'base_pay').gsub('max._total', 'total_pay') }
        next
      end
      hash = headers.zip(row.drop(1)).to_h.except("base").except('total')
      hash["year"] = year
      hash["full_name"] = hash["name"]
      hash.delete("name")
      hash["base_pay"] = hash["base_pay"].gsub(/[$,]/,'').to_f
      hash["total_pay"] = hash["total_pay"].gsub(/[$,]/,'').to_f
      hash = mark_empty_as_nil(hash)
      hash["md5_hash"] = make_md5(hash)
      if db_md5.include? hash["md5_hash"]
        md5_array << hash["md5_hash"]
        next
      end
      hash["run_id"] = run_id
      hash["touched_run_id"] = run_id
      data_array << hash
    end
    [data_array, md5_array]
  end

  private

  def make_md5(hash)
    md5 = MD5Hash.new(:columns => hash.keys)
    md5.generate(hash)
  end

  def mark_empty_as_nil(data_hash)
    data_hash.transform_values{|value| (value.to_s.empty? || value == 'null') ? nil : value.to_s.squish}
  end

end
