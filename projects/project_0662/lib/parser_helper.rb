module ParserHelper
  def create_md5_hash(data_hash)
    data_string = ''
    data_hash.values.each do |val|
      data_string += val.to_s
    end
    Digest::MD5.hexdigest data_string
  end

  def get_rows(xsl, index_1, text)
    xsl.default_sheet = xsl.sheets[index_1]
    data_lines = xsl.as_json
    ind = data_lines.index data_lines.select{ |a| a.to_s.squish.downcase.include? text}[0]
    [data_lines, ind]
  end

  def get_link(file)
    "https://www.cde.state.co.us#{file.split(".xlsx").first.gsub("_","/")}"
  end

  def get_year(file)
    year = file.split("_")[2].scan(/[0-9]/)[0..3].join.to_i
    "#{year}-#{year+1}"
  end

  def make_general_id(data_lines, data, ind, option, get_ids)
    if option.downcase.include? "state"
      nil
    elsif option.downcase.include? "district"
      code = get_data_column(data_lines, data, ind, "district code", 0)
      get_ids.select{ |a| a[2].to_s == "true" and a[0] == code}[0][1] rescue nil
    elsif option.downcase.include? "school"
      code = get_data_column(data_lines, data, ind, "school code", 0)
      get_ids.select{ |a| a[2].to_s == "false" and a[0] == code}[0][1] rescue nil
    end
  end

  def make_general_id_other(data_lines, data, ind, option1, option2, get_ids)
    code = get_data_column(data_lines, data, ind, option1, 0)
    id = get_ids.select{ |a| a[0] == code}[0][1] rescue nil
    code = get_data_column(data_lines, data, ind, option2, 0) if id.nil?
    id = get_ids.select{ |a| a[0] == code}[0][1] rescue nil
    id
  end

  def make_columns(case_information, link, run_id)
    case_info = {}
    case_info[:md5_hash]             = create_md5_hash(case_information)
    case_info[:data_source_url]      = get_link(link)
    case_info[:run_id]               = run_id
    case_info[:touched_run_id]       = run_id
    case_info
  end

  def iterator(index, ind, data_lines)
    (index <= ind) || (data_lines[index][0].nil?)
  end

  def get_xls_sheets(path)
    Roo::Spreadsheet.open(path)
  end
end
