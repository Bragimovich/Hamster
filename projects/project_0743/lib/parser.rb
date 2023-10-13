# frozen_string_literal: true
require 'roo'
require 'roo-xls'
require_relative 'keeper'
class Parser < Hamster::Parser
  def initialize
    super
    @keeper = Keeper.new
  end

  def parse_enrollment(path)
    hash_array   = []
    xlsx         = open_xls(path)
    file_name    = File.basename(path)
    sheet_name   = path.match(/Building/) ? 'Building_Enrollment' : 'Enrollment_by_Grade'
    sheet        = xlsx.sheet(sheet_name)
    sheet_headers = xlsx.first
    start_col    = sheet_headers.find_index{|h| h.match(/Pre-School/i)}
    sheet.parse.each_with_index do |row, ind|
      data_source = "#{file_name}/#{sheet_name}##{ind}"
      g_info      = get_general_info(sheet_headers, row, data_source)
      hash_data   = {data_source_url: data_source, school_year: file_name.match(/(\d.+-\d.+).xlsx/)[1], general_id: g_info.id}
      row.each_with_index do |col, c_ind|
        next if c_ind < start_col
        break if sheet_headers[c_ind].match(/watermark/i)
        
        hash_data[:count] = col
        grade = sheet_headers[c_ind].gsub(/enrollment/i, '').strip
        if !sheet_headers[c_ind].match(/enrollment$/i) && c_ind - start_col > 3
          hash_data[:subgroup] = grade
          hash_data[:grade] = nil
        else
          hash_data[:subgroup] = 'Grade'
          hash_data[:grade] = grade
        end
        hash_array << hash_data.merge(md5_hash: create_md5_hash(hash_data))
      end
    end
    hash_array
  end

  def parse_assessment(path)
    hash_array = []
    xlsx = open_xls(path)
    file_name = File.basename(path)
    sheet_name = 'Performance_Indicators'
    begin
      sheet = xlsx.sheet(sheet_name)
    rescue
      sheet_name = 'Report_Only_Indicators'
      sheet      = xlsx.sheet(sheet_name)
    end
    sheet_headers = xlsx.first
    start_col    = sheet_headers.find_index{|h| h.match(/3rd Grade/i)}
    sheet.parse.each_with_index do |row, ind|
      data_source = "#{file_name}/#{sheet_name}##{ind}"
      g_info      = get_general_info(sheet_headers, row, data_source)
      hash_data   = {data_source_url: data_source, general_id: g_info.id, school_year: file_name.match(/(\d.+-\d.+).xlsx/)[1]}
      row.each_with_index do |col, c_ind|
        next if c_ind < start_col
        break if sheet_headers[c_ind].match(/watermark/i)

        hash_data[:indicator] = sheet_headers[c_ind]
        hash_data[:percent] = col
        hash_array << hash_data.merge(md5_hash: create_md5_hash(hash_data))
      end
    end
    hash_array
  end

  def parse_graduation(path)
    hash_array  = []
    xlsx        = open_xls(path)
    file_name   = File.basename(path)
    sheet_names = xlsx.sheets
    sheet_names.each do |sheet_name|
      next if sheet_name == 'Data Notes'
      sheet        = xlsx.sheet(sheet_name)
      sheet_headers = xlsx.first
      if path.match(/State/)
        start_col = sheet_headers.find_index{|h| h.match(/subgroup|disaggregation/i)} || 0
      else
        start_col = sheet_headers.find_index{|h| h.match(/subgroup|disaggregation/i)} || 4
      end
      sheet.parse.each_with_index do |row, ind|
        next if row[0].nil? && row[1].nil?
        data_source  = "#{file_name}/#{sheet_name}##{ind}"
        g_info = get_general_info(sheet_headers, row, data_source)
        subgroup  = row[start_col]
        subgroup  = sheet_name if start_col == 4
        hash_data = {
          data_source_url: data_source, 
          general_id: g_info.id, 
          school_year: file_name.match(/(\d.+-\d.+).xls/)[1],
          criteria_group: sheet_name,
          subgroup: subgroup,
          numerator: row[start_col + 1],
          denominator: row[start_col + 2],
          graduation_rate: row[start_col + 3]
        }
        hash_array << hash_data.merge(md5_hash: create_md5_hash(hash_data))
      end
    end
    hash_array
  end

  def parse_gifted(path)
    hash_array  = []
    xlsx        = open_xls(path)
    file_name   = File.basename(path)
    if path.match(/Indicator/)
      sheet_name   = 'Gifted Indicator - Districts'
      sheet        = xlsx.sheet(sheet_name)
      sheet_headers = xlsx.first
      start_col    = sheet_headers.find_index{|h| h.match(/enrollment/i)}
      sheet.parse.each_with_index do |row, ind|
        data_source  = "#{file_name}##{ind}"
        general_info = get_general_info(sheet_headers, row, data_source)
        hash_data = {
          data_source_url: data_source, 
          general_id: general_info.id, 
          school_year: file_name.match(/(\d.+-\d.+).xls/)[1],
          enrollment: row[start_col],
          performance_idx: row[start_col + 1],
          not_identified: nil,
          ident_served: nil,
          ident_not_served: nil,
          identified: nil,
          served: nil
        }
        sheet_headers.each_with_index do |header, ind|
          if header.match(/ident/i)
            group = header.split.reject{|h| h.match(/ident/i) || h.match(/gifted/i) || h.match(/percent/i) || h=='-'}
            hash_data[:criteria_group] = group.join(' ')
            hash_data[:identified] = row[ind]
            hash_data[:served] = get_served_val(sheet_headers, row, header.split.last)
            hash_array << hash_data.merge(md5_hash: create_md5_hash(hash_data))
          end
        end
      end
    elsif path.match(/District/)
      year = file_name.match(/(\d.+-\d.+).xls/)[1]
      if year == '2021-2022'
        sheet_names = ['Gifted_Performance_Indicator', 'Gifted_Ident_and_Serv']
      else
        sheet_names = ['Gifted Indicator']
      end
      sheet_names.each do |sheet_name|
        sheet         = xlsx.sheet(sheet_name)
        sheet_headers = xlsx.first
        start_col     = sheet_headers.find_index{|h| h.match(/enrollment/i)}
        sheet.parse.each_with_index do |row, ind|
          find_col      = false
          data_source   = "#{file_name}/#{sheet_name}##{ind}"
          general_info  = get_general_info(sheet_headers, row, data_source)
          header_array  = []
          hash_sub_data = {}
          sheet_headers.each_with_index do |header, h_ind|
            hash_data = {
              data_source_url: data_source, 
              general_id: general_info.id, 
              school_year: year,
              enrollment: start_col ? row[start_col] : 'total',
              performance_idx: start_col ? row[start_col + 1] : 'total',
              not_identified: nil,
              ident_served: nil,
              ident_not_served: nil,
              identified: nil,
              criteria_group: nil,
              served: nil
            }
            if start_col
              if header.match(/identif/i) && header.match(/serv/i)
                group = header.split.reject{|h| h.match(/ident/i) || h.match(/gifted/i) || h.match(/and/i)}
                hash_data[:criteria_group] = group.join(' ')
                hash_data[:ident_served] = row[h_ind]
                hash_array << hash_data.merge(md5_hash: create_md5_hash(hash_data))
              elsif header.match(/identif/i)
                group = header.split.reject{|h| h.match(/ident/i) || h.match(/gifted/i) || h.match(/percent/i) || h=='-'}
                hash_data[:criteria_group] = group.join(' ')
                hash_data[:identified] = row[ind]
                hash_data[:served] = get_served_val(sheet_headers, row, header.split.last)
                hash_array << hash_data.merge(md5_hash: create_md5_hash(hash_data))
              end
            else
              if header.match(/serv/i) && header.match(/not/i)
                find_col = true
                hash_sub_data[:criteria_group] = get_group_val(header)
                hash_sub_data[:ident_not_served] = row[h_ind]
              elsif header.match(/identif/i) && header.match(/not/i)
                find_col = true
                hash_sub_data[:criteria_group] = get_group_val(header)
                hash_sub_data[:not_identified] = row[h_ind]
              elsif header.match(/serv/i)
                find_col = true
                hash_sub_data[:criteria_group] = get_group_val(header)
                hash_sub_data[:ident_served] = row[h_ind]
              elsif header.match(/identif/i)
                find_col = true
                hash_sub_data[:criteria_group] = get_group_val(header)
                hash_sub_data[:identified] = row[h_ind]
                hash_sub_data[:served] = get_served_val(sheet_headers, row, header.split.last)
              end
              header_array << hash_sub_data if find_col == true
              find_col     = false
              hash_sub_data  = {
                not_identified: nil,
                ident_served: nil,
                ident_not_served: nil,
                identified: nil,
                criteria_group: nil,
                served: nil
              }
            end
          end
          unless header_array.empty?
            groups = header_array.map{|a| a[:criteria_group]}.uniq
            groups.each do |g|
              hash_data = {
                data_source_url: data_source, 
                general_id: general_info.id, 
                school_year: year,
                enrollment: start_col ? row[start_col] : 'total',
                performance_idx: start_col ? row[start_col + 1] : 'total',
                criteria_group: nil,
                not_identified: nil,
                ident_served: nil,
                ident_not_served: nil,
                identified: nil,
                served: nil
              }
              arrays = header_array.select{|a| a[:criteria_group] == g}
              arrays.each do |a|
                hash_data[:criteria_group] = g
                hash_data[:not_identified] = a[:not_identified] if a[:not_identified]
                hash_data[:ident_served] = a[:ident_served] if a[:ident_served]
                hash_data[:ident_not_served] = a[:ident_not_served] if a[:ident_not_served]
                hash_data[:identified] = a[:identified] if a[:identified]
                hash_data[:served] = a[:served] if a[:served].nil?
              end
              hash_array << hash_data.merge(md5_hash: create_md5_hash(hash_data))
            end
          end
        end
      end
    end
    hash_array
  end

  def get_group_val(header)
    header.split(' - ').last
  end

  def get_served_val(headers, row, key)
    headers.each_with_index do |h, ind|
      return row[ind] if h.match(/serv/i) && h.match(/#{key}/i)
    end
  end

  def parse_attendance(path)
    hash_array  = []
    xlsx        = open_xls(path)
    file_name   = File.basename(path)
    if xlsx.sheets.include?('District_Disag_Attendance')
      sheet_names = ['District_Disag_Attendance', 'Building_Disag_Attendance']
    elsif xlsx.sheets.include?('District_Disag_Attendance_Rate')
      sheet_names = ['District_Disag_Attendance_Rate', 'Building_Disag_Attendance_Rate']
    end
    sheet_names.each do |sheet_name|
      start_col    = sheet_name.match(/building/i) ? 5 : 3
      sheet        = xlsx.sheet(sheet_name)
      sheet_headers = xlsx.first
      sheet.parse.each_with_index do |row, ind|
        data_source  = "#{file_name}/#{sheet_name}##{ind}"
        g_info       = get_general_info(sheet_headers, row, data_source)
        hash_data    = {
          data_source_url: data_source, 
          general_id: g_info.id, 
          school_year: file_name.match(/(\d.+-\d.+).xls/)[1],
          subgroup: row[start_col],
          rate: row[start_col+1]
        }
        hash_array << hash_data.merge(md5_hash: create_md5_hash(hash_data))
      end
    end
    hash_array
  end

  def parse_teacher(path)
    hash_array   = []
    file_name    = File.basename(path)
    sheet_name   = path.match(/Building/) ? 'BUILDING_Educator_Measures' : 'DISTRICT_Educator_Measures'
    xlsx         = open_xls(path)
    sheet        = xlsx.sheet(sheet_name)
    sheet_headers = xlsx.first
    start_col    = sheet_headers.find_index{|h| h.match(/Number of Lead/i)}
    sheet.parse.each_with_index do |row, ind|
      data_source  = "#{file_name}/#{sheet_name}##{ind}"
      g_info = get_general_info(sheet_headers, row, data_source)
      hash_data = {data_source_url: data_source, general_id: g_info.id, school_year: file_name.match(/(\d.+-\d.+).xlsx/)[1]}
      row.each_with_index do |col, c_ind|
        next if c_ind < start_col
        break if sheet_headers[c_ind].match(/Educator Evaluation/i)

        hash_data[:measure] = sheet_headers[c_ind]
        if hash_data[:measure].match(/percent|pct/i)
          hash_data[:value_type] = 'Percent'
          hash_data[:number] = nil
          hash_data[:percent] = col
        else
          hash_data[:value_type] = 'Number'
          hash_data[:number] = col
          hash_data[:percent] = nil
        end
        hash_array << hash_data.merge(md5_hash: create_md5_hash(hash_data))
      end
    end
    hash_array
  end

  def parse_expenditure(path)
    hash_array = []
    xlsx       = open_xls(path)
    file_name  = File.basename(path)
    sheet      = xlsx.sheet(0)
    sheet.parse.each_with_index do |row, ind|
      data_source  = "#{file_name}##{ind}"
      g_info       = @keeper.get_general_info(nil, nil, row[0], row[1], data_source)
      hash_data    = {data_source_url: data_source, general_id: g_info.id, school_year: file_name.match(/(\d{4}-\d{4})/)[1]}
      hash_data[:weighted_adm] = row[4].round(2)
      hash_data[:operating_total] = row[5].round(2)
      hash_data[:expend_per_equival_pupil] = row[6].round(2)
      hash_data[:cri] = row[7]
      hash_data[:ncr] = row[8]
      hash_data[:cri_epep] = row[9].round(2)
      hash_data[:ncr_epep] = row[10].round(2)
      hash_data[:cri_pct] = row[11].round(2)
      hash_data[:group_cri_pct_rank] = row[12]
      hash_data[:overall_cri_pct_rank] = row[13]
      hash_data[:overall_epep_rank] = row[14]
      hash_data[:operating_revenue] = row[15]
      hash_data[:federal] = row[16]
      hash_data[:state] = row[17]
      hash_data[:local] = row[18]
      hash_data[:other_non_tax] = row[19]
      hash_data[:lowest_20_pct_epep] = row[20]
      hash_data[:highest_20_pct_pi] = row[21]
      hash_array << hash_data.merge(md5_hash: create_md5_hash(hash_data))
    end
    hash_array
  end

  def create_md5_hash(hash)
    Digest::MD5.new.hexdigest(hash.map{|field| field.to_s}.join)
  end

  def open_xls(path)
    if path.match(/\.xls$/)
      Roo::Excel.new(path)
    else
      Roo::Spreadsheet.open(path)
    end
  end

  def get_general_info(headers, row, data_source)
    if headers[0].match(/Building/) && headers[2].match(/District|DIST/)
      @keeper.get_general_info(row[0], row[1], row[2], row[3], data_source)
    elsif headers[0].match(/District|DIST/) && headers[2].match(/Building/)
      @keeper.get_general_info(row[2], row[3], row[0], row[1], data_source)
    elsif headers[0].match(/District|DIST/) && !headers[2].match(/Building/)
      @keeper.get_general_info(nil, nil, row[0], row[1], data_source)
    elsif headers[0].match(/State/)
      @keeper.get_general_info(nil, nil, nil, row[0], data_source)
    elsif headers[0].match(/School/)
      @keeper.get_general_info(nil, nil, nil, row[1], data_source)
    end
  end
end
