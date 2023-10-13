# frozen_string_literal: true
require 'roo'

class Parser < Hamster::Parser

  def get_links(main_page)
    doc = Nokogiri::HTML5(main_page)
    doc.css('div.field-items a').map { |e| e['href'] }[0..-2]
  end

  def parser(path, run_id)
    data_array = []
    year = ''
    begin
      xlsx = Roo::Excelx.new(path) rescue nil
      return [] if xlsx.nil?

      worksheet_name = xlsx.sheets.first
      worksheet = xlsx.sheet(worksheet_name)
      header = [];
      worksheet.each_row_streaming(pad_cells: true) do |row|
        next if row.flatten.empty?

        row_cells = row.map { |cell| cell&.value }
        if row_cells[0].to_s.length > 30
          year = row_cells[0].split[0].split('>')
          year = year.count == 1 ? year[0] : year.last
        end
        next if  row_cells.reject { |e| e.nil? }.count < 5

        if ["TeacherNumber"].include?(row_cells[0]&.to_s)
          header = row_cells
        else
          data_array <<  conver_hash(row_cells, path, year, run_id)
        end
      end
    rescue Zip::Error => e
      Hamster.logger.error e
      Hamster.logger.error path
    end
    data_array
  end

  private

  def conver_hash(row, path, year, run_id)
    array = ['teacher_number', 'staff_id', 'county', 'county_name', 'district', 'district_name', 'site', 'school_name', 'race', 'race_desciption', 'gender', 'degree', 'degree_desciption', 'job_code', 'job_desciption', 'subject', 'subject_desciption', 'fte', 'base_salary', 'total_fringe', 'other_fringe', 'federal_base_salary', 'federal_fte', 'total_experience', 'district_paid_retirement', 'federal_fringe', 'retired_employee', 'state_flexible_benefits', 'total_extra_duty', 'total_other_salary', 'last_name', 'first_name', 'ocas_program_code', 'reason_for_leaving_code', 'reason_for_leaving', 'sort_order', 'email']
    if (path.split('/').last.to_i < 2017) and !(path.include? '2012')
      array.delete_at(20)
    end
    hash = {}
    array.each_with_index do |key, index|
      hash["#{key}"] = row[index]
    end
    hash[:fiscal_year] = year
    hash[:md5_hash] = create_md5_hash(hash)
    hash[:run_id] = run_id
    hash[:touched_run_id] = run_id
    hash[:data_source_url] = 'https://sde.ok.gov/documents/2018-01-02/certified-staff-salary-information'
    hash
  end

  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val| 
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end
end
