# frozen_string_literal: true

require 'roo'
require_relative '../lib/keeper'

class Manager < Hamster::Harvester
  def initialize
    super
  end

  def store
    keeper = Keeper.new
    Dir.glob('projects/project_0539/files/*').each do |file|
      file_type =  file.split('.').last
      if file_type == 'csv'
        doc = CSV.foreach(file, headers: false, col_sep: ",")
        count = 1
        row_count = doc.count
        headers = doc.first.map {|el| el}
        doc.each_with_index do |row, index|
          next if index == 0
          hash = Hash.new
          row.each_with_index do |value, row_index|
            hash[headers[row_index]] = value
          end
          date = (hash['SCHOOL YEAR'] || hash['SCH_YEAR']).to_s.match(/(\d{4})(\d{4})/) if index == 1
          keeper.school_year = "#{date[1]}-#{date[2]}" if index == 1
          #keeper.district(hash)
          #keeper.administrators(hash)
          #keeper.enrollment_csv(hash)
          #keeper.dropout_csv(hash)
          #keeper.assessment(hash)
          #keeper.assessment_act(hash)
          #keeper.assesment_national(hash)
          #keeper.graduation_rate(hash)
          #keeper.climate_index(hash)
          #keeper.climate(hash)
          #keeper.safety_events_csv(hash)
          #keeper.safety_audit(hash)
          if count == 2000 || index == row_count - 1
            #keeper.store_district
            #keeper.store_administrators
            #keeper.store_enrollment
            #keeper.store_assessment
            #keeper.store_assessment_act
            #keeper.store_assesment_national
            #keeper.store_graduation_rate
            #keeper.store_climate_index
            #keeper.store_climate
            #keeper.store_safety_events
            #keeper.store_safety_audit
            count = 0
          end
          count += 1
        end
      else
        workbook = Roo::Spreadsheet.open(file)
        worksheets = workbook.sheet(0)
        stream = worksheets.each_row_streaming(pad_cells: true)
        row_count = stream.count
        count = 1
        headers = stream.first.map { |cell| cell.value }
        stream.each_with_index do |row, index|
          next if index == 0
          hash = Hash.new
          row.each_with_index do |val, index|
            hash[headers[index]] = val.value rescue nil
          end
          date = (hash['SCHOOL YEAR'] || hash['SCH_YEAR']).to_s.match(/(\d{4})(\d{4})/) if index == 1
          keeper.school_year = "#{date[1]}-#{date[2]}" if index == 1
          #keeper.district(hash)
          #keeper.administrators(hash)
          #keeper.enrollment(hash)
          #keeper.enrollment_new(hash)
          #keeper.dropout(hash)
          #keeper.assessment(hash)
          #keeper.assessment_act(hash)
          #keeper.assesment_national(hash)
          #keeper.graduation_rate(hash)
          #keeper.safety_events(hash)
          if count == 1000 || index == row_count - 1
            #keeper.store_district
            #keeper.store_administrators
            #keeper.store_enrollment
            #keeper.store_assessment #4000
            #keeper.store_assessment_act
            #keeper.store_assesment_national
            #keeper.store_graduation_rate
            #keeper.store_safety_events #1000
            count = 0
          end
          count += 1
        end
      end
    end
  end
end
