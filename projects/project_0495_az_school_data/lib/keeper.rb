# frozen_string_literal: true

require_relative 'attributes_helper'
require_relative 'dataset_correction_helper'

class Keeper
  include AttributesHelper
  include DataSetCorrectionHelper

  def store_az_assessment(data)

    array_hashes = data.is_a?(Array) ? data : [data]
    main_arr = []
    array_hashes.each do |hash_data|
      hash_data_new = hash_data.merge({
        'data_source_url' => 'https://www.azed.gov/accountability-research/data/',
        'created_by' => 'William Devries',
        'report_date' => DateTime.now,
        'md5_hash' => get_md5_hash(hash_data)
      })
      digest = AzAssessment.find_by(md5_hash: md5_hash, deleted: false)
      if digest.nil?
        main_arr << hash_data_new
      else
        digest.update(hash_data_new)
      end
    end

    unless main_arr.nil? || main_arr.empty?
      AzAssessment.insert_all(main_arr)
    end
  end

  def store_az_enrollment(data)

    array_hashes = data.is_a?(Array) ? data : [data]
    main_arr = []
    array_hashes.each do |hash_data|
      hash_data_new = hash_data.merge({
        'data_source_url' => 'https://www.azed.gov/accountability-research/data/',
        'created_by' => 'William Devries',
        'report_date' => DateTime.now,
        'md5_hash' => get_md5_hash_az_enrollment(hash_data)
      })
      digest = AzEnrollment.find_by(md5_hash: md5_hash, deleted: false)
      if digest.nil?
        main_arr << hash_data_new
      else
        digest.update(hash_data_new)
      end
    end

    unless main_arr.nil? || main_arr.empty?
      AzEnrollment.insert_all(main_arr)
    end
  end
  
  def store_az_dropout(data)

    array_hashes = data.is_a?(Array) ? data : [data]
    main_arr = []
    array_hashes.each do |hash_data|
      hash_data_new = hash_data.merge({
        'data_source_url' => 'https://www.azed.gov/accountability-research/data/',
        'created_by' => 'William Devries',
        'report_date' => DateTime.now,
        'md5_hash' => get_md5_hash_az_dropout(hash_data)
      })

      digest = AzDropout.find_by(md5_hash: md5_hash, deleted: false)
      if digest.nil?
        main_arr << hash_data_new
      else
        digest.update(hash_data_new)
      end
    end

    unless main_arr.nil? || main_arr.empty?
      AzDropout.insert_all(main_arr)
    end
  end

  def store_az_cohort(data)
    array_hashes = data.is_a?(Array) ? data : [data]
    main_arr = []
    array_hashes.each do |hash_data|
      hash_data_new = hash_data.merge({
        'data_source_url' => 'https://www.azed.gov/accountability-research/data/',
        'created_by' => 'William Devries',
        'report_date' => DateTime.now,
        'md5_hash' => get_md5_hash_az_cohort(hash_data)
      })
      digest = AzCohort.find_by(md5_hash: md5_hash, deleted: false)
      if digest.nil?
        main_arr << hash_data_new
      else
        digest.update(hash_data_new)
      end
    end

    unless main_arr.nil? || main_arr.empty?
      AzCohort.insert_all(main_arr)
    end
  end

  def store_az_enrollment_from_xlsx(roo_xlsx, year)
    header_cells = []
    data_arr = []
    roo_xlsx.sheets.each do |sheet_name|
      next unless sheets_for_enrollment_data.include?(sheet_name)
      worksheet = roo_xlsx.sheet(sheet_name)
      worksheet.each_row_streaming(pad_cells: true) do |row|

        next if row.flatten.empty?
        row_cells = row.map { |cell| cell&.value }
        
        if row_cells.include?('Fiscal Year')
          header_cells = row_cells.map{|cell| cell.to_s.downcase.split(/\s/).join('_').split("/").join('_')}
          header_cells = header_converted_enrollment(header_cells)
          output_missing_columns_for_enrollment(header_cells)
          next
        end

        next if header_cells.empty?
        if row_cells.size < header_cells.size
          row_cells += [nil] * (header_cells.size - row_cells.size)
        end
        row_cells = row_cells.map{|cell| cell == '*' ? '< 10' : cell }        
        row = Hash[[header_cells, row_cells].transpose]
        row= row.slice(*az_enrollment_columns)
        
        # Add additional column
        row['school_year'] = "#{year-1}-#{year}"
        row['data_type'] = sheet_name.downcase.split(' ').join('_')
        
        data_arr << row
        if data_arr.length > 0
          store_az_enrollment(data_arr)
          data_arr = []
        end

      end
      if data_arr.length > 0
        store_az_enrollment(data_arr)
      end
    end
  end

  def store_az_assessment_from_xlsx(roo_xlsx, year)
    header_cells = []
    data_arr = []
    roo_xlsx.sheets.each do |sheet_name|
      next unless sheets_for_assessment_data.include?(sheet_name)
      worksheet = roo_xlsx.sheet(sheet_name)
      worksheet.each_row_streaming(pad_cells: true) do |row|

        next if row.flatten.empty?
        row_cells = row.map { |cell| cell&.value }
        
        if row_cells.include?('Fiscal Year') || row_cells.include?('District CTDS') 
          header_cells = row_cells.map{|cell| cell.downcase.split(/\s/).join('_')}
          header_cells = header_converted(header_cells)
          next
        end
        next if header_cells.empty?
        if row_cells.size < header_cells.size
          row_cells += [nil] * (header_cells.size - row_cells.size)
        end
        row_cells = row_cells.map{|cell| cell == '*' ? '< 10' : cell }
        
        row = Hash[[header_cells, row_cells].transpose]
        row= row.slice(*az_assessment_columns)
        
        # Add additional column
        row['year'] = year
        row['data_type'] = sheet_name.downcase.split(' ').join('_')
        
        data_arr << row
        if data_arr.length > 0
          store_az_assessment(data_arr)
          data_arr = []
        end
      end
      if data_arr.length > 0
        store_az_assessment(data_arr)
      end
    end
  end

  def store_az_dropout_from_xlsx(roo_xlsx, year)
    header_cells = []
    data_arr = []
    roo_xlsx.sheets.each do |sheet_name|
      next unless sheets_for_dropout_data.include?(sheet_name)
      worksheet = roo_xlsx.sheet(sheet_name)
      worksheet.each_row_streaming(pad_cells: true) do |row|

        next if row.flatten.empty?
        row_cells = row.map { |cell| cell&.value }
        
        if row_cells.include?('Fiscal Year')
          header_cells = row_cells.map{|cell| cell.to_s.downcase.split(/\s/).join('_').split("/").join('_')}
          header_cells = header_converted_dropout(header_cells)
          next
        end
        next if header_cells.empty?
        if row_cells.size < header_cells.size
          row_cells += [nil] * (header_cells.size - row_cells.size)
        end        
        row = Hash[[header_cells, row_cells].transpose]
        row= row.slice(*az_dropout_columns)
        
        # Add additional column
        row['year'] = year
        row['dataset_name_prefix'] = 'az_school'
        row['data_type'] = sheet_name.downcase.split(' ').join('_')
        
        data_arr << row
        if data_arr.length > 0
          store_az_dropout(data_arr)
          data_arr = []
        end
      end
      if data_arr.length > 0
        store_az_dropout(data_arr)
      end
    end  
  end
  
  def store_az_cohort_from_xlsx(roo_xlsx, year)
    header_cells = []
    data_arr = []
    roo_xlsx.sheets.each do |sheet_name|
      next unless sheets_for_cohort_data.include?(sheet_name)
      
      worksheet = roo_xlsx.sheet(sheet_name)
      worksheet.each_row_streaming(pad_cells: true) do |row|

        next if row.flatten.empty?
        row_cells = row.map { |cell| cell&.value }
        
        if row_cells.include?('Cohort Year')
          header_cells = row_cells.map{|cell| cell.to_s.downcase.split(/\s/).join('_').split("/").join('_')}
          header_cells = header_converted_cohort(header_cells)
          next
        end
        next if header_cells.empty?
        if row_cells.size < header_cells.size
          row_cells += [nil] * (header_cells.size - row_cells.size)
        end        
        row = Hash[[header_cells, row_cells].transpose]
        row= row.slice(*az_dropout_columns)
        
        # Add additional column
        row['year'] = year
        row['dataset_name_prefix'] = 'az_school'
        row['data_type'] = sheet_name.downcase.split(' ').join('_')
        
        data_arr << row
        if data_arr.length > 0
          store_az_cohort(data_arr)
          data_arr = []
        end
      end
      if data_arr.length > 0
        store_az_cohort(data_arr)
      end
    end  
  end
  
  def get_md5_hash(hash_data)
    data_str = hash_data.slice(*assessment_key_params).values.join('')
    md5_hash = Digest::MD5.hexdigest(data_str)
  end

  def get_md5_hash_az_enrollment(hash_data)
    data_str = hash_data.slice(*enrollment_key_params).values.join('')
    md5_hash = Digest::MD5.hexdigest(data_str)
  end

  def get_md5_hash_az_dropout(hash_data)
    data_str = hash_data.slice(*dropout_key_params).values.join('')
    md5_hash = Digest::MD5.hexdigest(data_str)
  end

  def get_md5_hash_az_cohort(hash_data)
    data_str = hash_data.slice(*cohort_key_params).values.join('')
    md5_hash = Digest::MD5.hexdigest(data_str)
  end
end
