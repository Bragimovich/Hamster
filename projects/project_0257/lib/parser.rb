require_relative '../lib/scraper'

class Parser < Hamster::Parser

  def parse_row(line, run_id)
    data_hash = {}
    puts line
    row = CSV.parse(line, liberal_parsing: true ,encoding: 'Windows-1252').flatten
    data_hash[:run_id]       = run_id
    data_hash[:full_name]    = row.first
    data_hash[:first_name], data_hash[:middle_name], data_hash[:last_name] = name_split(data_hash[:full_name])
    data_hash[:title]        = row[1]
    data_hash[:salary]       = row[2]
    data_hash[:travel]       = row[3]
    data_hash[:organization] = row[4]
    data_hash[:fiscal_year]  = row[5]
    data_hash
  end

  private

  def name_split(name)
    last_name, first_name, middle_name = nil
    return [first_name, middle_name, last_name] if name == nil or name == ','
    last_name, first_name = (name.split(",").count > 1) ? name.split(",") : name.split(" ")
    if first_name.split(" ").count == 2
      first_name,middle_name = first_name.split(" ")
    else last_name.split(" ").count == 2
      last_name, middle_name = last_name.split(" ")
    end
    [first_name.strip, middle_name, last_name]
  end
end
