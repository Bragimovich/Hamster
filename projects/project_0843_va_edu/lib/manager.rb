# frozen_string_literal: true

require_relative '../lib/scraper'
require_relative '../lib/parser'
require_relative '../lib/keeper'

require 'pry'

class Manager < Hamster::Harvester
  attr_accessor :keeper, :parser, :scraper, :run_id

  def initialize
    @scraper = Scraper.new
    @parser = Parser.new
    @keeper = Keeper.new
    @run_id = @keeper.run_id.to_s
  end

  def store_general_info
    keeper.store_general_info
    keeper.mark_delete
    keeper.finish
  end

  def store_enrollment
    file_names = [
      'fall_membership_statistics_20182019.csv',
      'fall_membership_statistics_20172018.csv',
      'fall_membership_statistics_20162017.csv',
      'fall_membership_statistics_20152016.csv',
      'fall_membership_statistics_20142015.csv',
    ]
    file_names.each do |file_name|        
      raw_data = scraper.get_csv_file(file_name, 'enrollment')
      csv_data = parser.parse_enrollment(raw_data)
      keeper.store_enrollment(csv_data)
    end
  end

  def store_discipline
    2022.downto(2015) do |year|
      Hamster.logger.debug "Started #{year}"
      store_discipline_state(year) #Done
      store_discipline_division(year) #Done
      store_discipline_school(year)
    end
    
  end

  def store_discipline_state(year)
    file_name = "chronic-absenteeism-state-#{year}.xlsx"
    json_data = scraper.get_json_from_xlsx(file_name, 'discipline')
    keeper.store_discipline_state(json_data)
  end

  def store_discipline_division(year)
    file_name = "chronic-absenteeism-div-#{year}.xlsx"
    json_data = scraper.get_json_from_xlsx(file_name, 'discipline')
    keeper.store_discipline_division(json_data)
  end

  def store_discipline_school(year)
    file_name = "chronic-absenteeism-school-#{year}.xlsx"
    file_path = scraper.storehouse + "store/discipline/#{file_name}"
    workbook = Roo::Spreadsheet.open(file_path)
    worksheets = workbook.sheet(0)
    stream = worksheets.each_row_streaming(pad_cells: true)
    hash_headers = {}
    stream.each_with_index do |row, index|
      if index == 0
        row.each_with_index do |v, i|
          hash_headers[v.value] = i
        end
        break
      end
    end
    stream.each_with_index do |row, index|
      next if index == 0
      keeper.store_discipline_school_from_stream(row.map(&:value), hash_headers)
    end
  end

  def store_finances_receipts
    2022.downto(2002) do |year|
      store_finances_receipts_for(year)
    end
  end

  def store_finances_receipts_for(year)
    Hamster.logger.debug "Started storing finances receipts for #{year}"
    directory_path = scraper.storehouse + "store/finances_receipts"
    
    files = Dir.glob("#{directory_path}/*")
    directory_path = scraper.storehouse + "store/finances_receipts"

    if year >= 2018
      files = files.select{|name| name.include?("fy#{year-2000}.xls")}
    elsif year == 2017
      files = files.select{|name| name.include?("2016-17")}
    elsif year < 2017
      files = files.select{|name| name.include?("#{year-1} - #{year}.xlsx")}
    end
    
    files.each do |file_path|

      json_data = scraper.get_json_from_full_path_xlsx(file_path)
      
      hash_headers = {}
      last_index = 0
      json_data.each_with_index do |row, index|
        next if row[0].nil?
        next unless row[0] =~ /Division Number/i
        hash_headers = parser.parse_finances_receipts_headers(row)
        last_index = index
        break
      end
      
      cnt_records = 0
      json_data.each_with_index do |row, index|
        next if index <= last_index
        next if row[0].nil?
        next unless is_validate_div_num(row[hash_headers['div_num']])
        break if row[1].to_s =~ /Percent of Total Receipts/i
        break if row[1].to_s =~ /STATE TOTAL/i
        hash_data = {
          fiscal_year: year,
          div_num: row[hash_headers['div_num']],
          div_name: row[hash_headers['div_name']],
          state_sales: row[hash_headers['state_sales']],
          state_funds: row[hash_headers['state_funds']],
          federal_funds: row[hash_headers['federal_funds']],
          local_funds: row[hash_headers['local_funds']],
          other_funds: row[hash_headers['other_funds']],
          loan_bonds: row[hash_headers['loan_bonds']],
          total_receipts: row[hash_headers['total_receipts']],
          balances_bg_year: row[hash_headers['balances_bg_year']],
          balances_receipts: row[hash_headers['balances_receipts']]
        }

        keeper.store_finances_receipts(hash_data)
        cnt_records += 1
      end
      Hamster.logger.debug "Inserted #{cnt_records}"
    end
    Hamster.logger.debug "Finished storing finances receipts for #{year}"
  end

  def is_validate_div_num(num)
    return true if num.is_a?(Integer) && num != 0
  end

  def store_finances_expenditures
    2022.downto(2002) do |year|
      store_finances_expenditures_for(year)
    end
  end

  def store_finances_expenditures_for(year)
    Hamster.logger.debug "Started storing finances expenditures for #{year}"
    directory_path = scraper.storehouse + "store/finances_expenditures"
    
    files = Dir.glob("#{directory_path}/*")

    if year >= 2017
      files = files.select{|name| name.include?("final-fy#{year-2000}")}
    elsif year >= 2014
      # FY 2014 Table 15 Final.xlsm, FY 2015 Table 15 Revised for Lee County.xlsm, FY2016 Table 15 Final with worksheets.xlsm
      files = files.select{|name| name.include?("#{year} Table 15")}
    elsif year <= 2013
      files = files.select{|name| name.include?("#{year-1} - #{year}.xlsx")}
    end
    
    if files.empty?
      Hamster.logger.debug "There is no finances expenditures file for #{year}"
      return
    end
    files.each do |file_path|

      json_data = scraper.get_json_from_full_path_xlsx(file_path)
      # data_arr = parser.parse_finances_receipts_for_schools(json_data)
      last_index = 0
      json_data.each_with_index do |row, index|
        next unless row[0] =~ /Fiscal Year #{year}/i
        last_index = index
        break
      end

      cnt_records = 0
      json_data.each_with_index do |row, index|
        next if index <= last_index
        next if row[0].nil?
        next unless is_validate_div_num(row[0])
        break if row[1].to_s =~ /State/i
        keeper.store_finances_expenditures(row, year)
        cnt_records += 1
      end
      Hamster.logger.debug "Inserted #{cnt_records}"

      # data_arr = parser.parse_finances_receipts_for_counties(json_data)
    end
    Hamster.logger.debug "Finished storing finances expenditures for #{year}"
  end

  def store_finances_salaries
    2022.downto(2002) do |year|
      store_finances_salaries_for(year)
    end
  end

  def store_finances_salaries_for(year)
    Hamster.logger.debug "Started storing finances salaries for #{year}"
    directory_path = scraper.storehouse + "store/finances_salaries"
    
    files = Dir.glob("#{directory_path}/*")

    if year >= 2018
      files = files.select{|name| name.include?("table19-fy#{year-2000}")}
    elsif year == 2017
      files = files.select{|name| name.include?("2016-17-table-19.xlsx")}
    elsif year <= 2017
      files = files.select{|name| name.include?("#{year-1} - #{year}.xls")}
    end
    
    if files.empty?
      Hamster.logger.debug "There is no finances salaries file for #{year}"
      return
    end
    files.each do |file_path|
      json_data = scraper.get_json_from_full_path_xlsx(file_path)
      last_index = 0
      json_data.each_with_index do |row, index|
        if year > 2003
          next unless row[0] =~ /Fiscal Year #{year}/i
        else
          next unless row[0] =~ /#{year-1} - #{year}/i
        end
        last_index = index
        break
      end
      cnt_records = 0
      json_data.each_with_index do |row, index|
        next if index <= last_index
        next if row[0].nil?
        next unless is_validate_div_num(row[0])
        break if row[1].to_s =~ /State/i
        keeper.store_finances_salaries(row, year)
        cnt_records += 1
      end
      Hamster.logger.debug "Inserted #{cnt_records}"
    end
    Hamster.logger.debug "Finished storing finances salaries for #{year}"
  end

end


